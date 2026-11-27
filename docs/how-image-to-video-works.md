# How an AI turns one picture into a video

Written for people and for AI agents who need to work with image to video models and do not want to spend a day learning the basics. Wan 2.2 is the example, but most open video models (Hunyuan Video, LTX Video, CogVideoX) work the same way.

## The one sentence version

The model starts with a block of random noise shaped like a small video, and removes the noise in a few steps, while being told two things: "the first frame must be this picture" and "the video should match this text".

## The four parts

| Part | In Wan 2.2 | Job |
|---|---|---|
| Text encoder | umT5-XXL | Turns the prompt into a list of vectors. Runs once. |
| Video VAE | Wan 2.1 VAE | Shrinks pixels into a small "latent" video and back. Runs once at the start and once at the end. |
| Denoiser | a 14B transformer (40 layers, width 5120), in two copies | Predicts how to turn noise into video. Runs once per step. This is where the time goes. |
| Sampler | euler, flow matching | The loop that calls the denoiser and applies each step. |

## Step by step

### 1. The picture and the video are shrunk first

Working on real pixels would be far too slow. The VAE shrinks 8 times in width, 8 times in height and 4 times in time, into 16 channels.

- 832x480 pixels becomes 104x60 in latent space.
- 81 frames becomes 21 latent frames: (81 - 1) / 4 + 1. This is why the frame count must be 4n + 1 (17, 33, 49, 81).

The model then cuts each latent frame into 2x2 patches. Each patch is one "token", the same idea as a word in a text model.

| Size | Frames | Tokens the model works on |
|---|---|---|
| 832x480 | 81 | 52 x 30 x 21 = 32,760 |
| 832x480 | 17 | 52 x 30 x 5 = 7,800 |
| 480x272 | 81 | 30 x 17 x 21 = 10,710 |
| 1280x720 | 81 | 80 x 45 x 21 = 75,600 |

Token count is the number that decides speed and memory. Every token looks at every other token (attention), so cost grows faster than the token count. Halving width and height cuts tokens by 4.

### 2. How the start picture is given to the model

The start picture is run through the VAE and placed as the first latent frame. The other frames are left empty. A mask says which frames are given and which must be invented. The picture latent and the mask are glued onto the noise as extra input channels, so at every step the model can see the picture it must start from.

This is why image to video keeps the character on model in the first frames and drifts later: the further a frame is from the given one, the less it is pinned.

### 3. The noise is removed in steps

The model was trained with flow matching: take a real video, mix it with noise by some amount t between 0 (clean) and 1 (pure noise), and learn to predict the direction from noise to clean. At generation time you start at t = 1 and walk to t = 0 in steps.

- **Early steps (high noise)** decide the big things: layout, who moves where, camera motion.
- **Late steps (low noise)** decide the small things: faces, texture, light, sharpness.

Wan 2.2 trained two separate models for this, called experts. The high noise expert runs while t is above 0.9, the low noise expert finishes the job. Only one is needed in memory at a time. If the motion is wrong, look at the high noise half. If the face or detail is wrong, look at the low noise half.

**Shift** bends the schedule so more of the steps are spent at high noise. Bigger videos need a bigger shift. Wan's own default is 5.

### 4. How the text steers it (cfg)

At each step the model is normally run twice: once with your prompt and once with the negative prompt. The result is pushed away from the negative one and toward yours. The strength of the push is cfg. Wan's default is 3.5.

At cfg 1 there is no push and the second run is skipped. That halves the work, and the negative prompt does nothing.

### 5. Back to pixels

The VAE turns the clean latent into frames. On a CPU this takes minutes, not hours, but it has a memory peak of its own.

## Why it is slow, and what each speed trick does

Total work is roughly: steps x (1 or 2 model runs per step) x cost per run. The official settings are 40 steps at cfg 3.5, so 80 runs of a 14B model.

| Trick | What it changes | Saves | Costs |
|---|---|---|---|
| Step distillation LoRA (Lightning, lightx2v) | A small add-on trained to copy the 40 step result in 4 steps at cfg 1 | 80 runs become 4, about 20 times | Slower, softer motion, less variety, negative prompt ignored |
| Quantization (GGUF Q4, Q8, fp8) | Stores the weights with fewer bits | Disk and memory, 28.6 GB to 9.65 GB per expert at Q4 | Small quality loss. Not faster on CPU |
| Lower resolution | Fewer tokens | Roughly in line with the token count or better | Below the trained size (480p) motion stalls and light effects vanish |
| Fewer frames | Fewer tokens | Same | Shorter clip. Filling frames in after gives slow motion, not a longer action |
| Smaller model (5B) | Cost per run | About 12 times in our test | Faces drift, colours worse |
| Frame interpolation (RIFE) | Adds in-between frames after | Cheap smoothness | Cannot add new action |
| Upscaling (Real-ESRGAN) | Enlarges after | Cheap pixels | Cannot bring back motion or light that was never drawn |

The lesson in one line: the tricks that keep the model at its trained size (distillation, quantization) cost little quality, and the tricks that take it below its trained size (tiny resolution, tiny model) cost a lot.

## Related modes you will meet

- **Text to video (T2V)**: same thing with no start picture.
- **First and last frame (FLF)**: two pictures pinned, the model fills the middle.
- **Video to video (V2V)**: start from an existing clip with noise added to it, not from pure noise. Only the last part of the walk is run, so the layout and motion of the input are kept and the look is repainted. With a two expert model this needs only the low noise expert.
- **Control models (VACE, Fun Control)**: the motion comes from a guide video such as depth, pose or line art.

## Words you will see

| Word | Meaning |
|---|---|
| Latent | The small hidden form of the video the model works on |
| DiT | Diffusion transformer, the denoiser |
| Expert | One of the two denoisers in Wan 2.2 (high noise, low noise) |
| LoRA | A small add-on file that changes a model's behaviour |
| Distillation | Training a model or LoRA to do in few steps what the original does in many |
| GGUF, Q4, Q8 | A file format for weights stored with fewer bits. Lower number, smaller file |
| cfg | Classifier free guidance, how hard the prompt pushes |
| Shift | Bends the noise schedule toward high noise |
| I2V, T2V, V2V | Image, text, video to video |

## Sources

- Wan 2.2 code and configs: https://github.com/Wan-Video/Wan2.2 (the numbers above for layers, width, compression, boundary 0.9, shift 5, 40 steps, cfg 3.5 are from `wan/configs/wan_i2v_A14B.py`)
- Lightning LoRA: https://github.com/ModelTC/Wan2.2-Lightning
