# Wan 2.2 image to video, on your own machine

Turn one picture and one line of text into a 5 second video clip with the free Wan 2.2 model, on your own computer. No account, no credits, no cloud.

This is the exact setup we run, with every download link, the settings, and the times we measured. It works with or without a graphics card. Without one it is slow, and the numbers below say how slow.

## More to read

- [How an AI turns one picture into a video](docs/how-image-to-video-works.md): the mechanism and what each speed trick costs.
- [Lessons learned](docs/lessons-learned.md): every number we measured, what failed, what to try first.
- [AGENTS.md](AGENTS.md): a short entry point for AI agents.

## How it works

Wan 2.2 is a video model released for free by Alibaba. You give it a start picture and a prompt. It writes the next frames.

1. **The text reader** (umt5-xxl) turns your prompt into numbers the model understands.
2. **The picture coder** (VAE) shrinks your start picture into a small hidden form. The model works on that small form, not on full pixels.
3. **The video model** starts from pure noise and cleans it up step by step until it becomes a video that starts at your picture and follows your prompt. Wan 2.2 has two halves:
   - the **high noise** half does the first steps. It decides the motion and the layout.
   - the **low noise** half does the last steps. It adds detail, faces and light.
4. **The picture coder** turns the result back into real frames, and they are saved as an mp4 at 16 frames per second.

The full model needs about 40 steps. Two tricks make it usable on a normal machine:

- **Smaller files (GGUF, "Q4")**: the model's numbers are stored with less precision. Each half goes from about 28 GB to 9.65 GB, with a small loss in quality.
- **Lightning LoRA**: a small add-on file that teaches the model to finish in 4 steps (2 on each half) in place of about 40. This is the biggest time saver.

## Choose your version

There are three versions here. All use the same Wan 2.2 14B model. Pick by what your machine can take.

| | 1. Optimized (speed-up) | 2. Pure, small files | 3. Pure, original files |
|---|---|---|---|
| What it is | Q4 files plus the Lightning LoRA | Q4 files, no speed-up add-on | Full original files, no speed-up add-on |
| Steps | 4 | 20 | 20 |
| Download | 26 GB | 24 GB | 62 GB |
| Works with no graphics card | yes, slow | too slow to be useful | no |
| Graphics memory needed | 12 GB or more | 12 GB or more | 24 GB or more |
| Quality | very good | a little more natural motion | the reference: best motion and detail |
| Tested by us | yes | no | no |
| Download command | `bash download.sh optimized` | `bash download.sh pure-q4` | `bash download.sh pure-original` |
| Workflow file | `workflows/optimized_q4_lightning_4steps_832x480.json` | `workflows/pure_q4_20steps_832x480.json` | `workflows/pure_original_fp16_20steps_832x480.json` |

What "pure" means: the model runs the way it was released, 20 steps with cfg 3.5, with no Lightning LoRA. The speed-up LoRA saves about 10 times the work, and the cost is slightly slower, softer motion. The pure settings (20 steps, cfg 3.5, shift 8, 10 steps on each half) come from ComfyUI's stock Wan 2.2 template. We have not run versions 2 and 3 ourselves, because our machine has no graphics card.

`bash download.sh all` gets everything, so you can switch between them.

### What we measured with the optimized version

Our machine: 8 CPU cores (AMD EPYC), 31 GB RAM, no graphics card.

| | Best quality | Fast preview |
|---|---|---|
| Size | 832x480, 81 frames (5 s) | 480x272, 81 frames (5 s), enlarged after |
| Time | 11 h 53 min | about 2 h 20 min |
| Peak memory | 25.9 GB | about 20 GB |
| Result | clean face, smooth motion, good light and glow | motion can stall for a moment, glow and light rays are lost |
| Workflow file | `optimized_q4_lightning_4steps_832x480.json` | `optimized_q4_lightning_4steps_480x272.json` |

Both rows use the same model. The only difference is the size it draws at. The model was trained at 480p and 720p, so going far below that hurts motion and light. If you care about the result, use 832x480.

With an NVIDIA card the same files run many times faster. We have not measured that.

## What you need

- Free disk: 30 GB for the optimized version, 70 GB for the original files.
- No graphics card: 32 GB RAM for 832x480, and patience.
- NVIDIA card: 12 GB of graphics memory or more is comfortable for these files.
- Python 3.10 or newer, and git.

## Setup

### 1. Install ComfyUI and the two add-ons

```bash
git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cd custom_nodes
git clone https://github.com/city96/ComfyUI-GGUF
pip install -r ComfyUI-GGUF/requirements.txt
git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation
cd ../..
```

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) is the program that runs the model.
- [ComfyUI-GGUF](https://github.com/city96/ComfyUI-GGUF) loads the smaller `.gguf` files. Required.
- [ComfyUI-Frame-Interpolation](https://github.com/Fannovel16/ComfyUI-Frame-Interpolation) adds in-between frames. Optional.
- With an NVIDIA card, install the CUDA build of PyTorch before `pip install -r requirements.txt`: https://pytorch.org/get-started/locally/

Versions we run: ComfyUI `ef50715`, ComfyUI-GGUF `6ea2651`, ComfyUI-Frame-Interpolation `26545cc`.

### 2. Download the model files

Pick one (see the table above):

```bash
bash download.sh optimized
```

```bash
bash download.sh pure-q4
```

```bash
bash download.sh pure-original
```

Run it from the folder that holds `ComfyUI`. A second argument sets another models folder.

The script can be stopped and started again. It skips files that are already there. These are the files for the optimized version:

| What | Size | Folder in `ComfyUI/models` | Link |
|---|---|---|---|
| Video model, high noise half (Q4) | 9.65 GB | `unet/` | [Wan2.2-I2V-A14B-HighNoise-Q4_K_M.gguf](https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/HighNoise/Wan2.2-I2V-A14B-HighNoise-Q4_K_M.gguf) |
| Video model, low noise half (Q4) | 9.65 GB | `unet/` | [Wan2.2-I2V-A14B-LowNoise-Q4_K_M.gguf](https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-I2V-A14B-LowNoise-Q4_K_M.gguf) |
| Lightning 4 step LoRA, high | 1.23 GB | `loras/lightning_i2v_high.safetensors` | [high_noise_model.safetensors](https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/high_noise_model.safetensors) |
| Lightning 4 step LoRA, low | 1.23 GB | `loras/lightning_i2v_low.safetensors` | [low_noise_model.safetensors](https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-I2V-A14B-4steps-lora-rank64-Seko-V1/low_noise_model.safetensors) |
| Text reader (umt5-xxl, Q5) | 4.15 GB | `text_encoders/` | [umt5-xxl-encoder-Q5_K_M.gguf](https://huggingface.co/city96/umt5-xxl-encoder-gguf/resolve/main/umt5-xxl-encoder-Q5_K_M.gguf) |
| Picture coder (Wan 2.1 VAE) | 0.25 GB | `vae/wan_2.1_vae.safetensors` | [Wan2.1_VAE.safetensors](https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/resolve/main/VAE/Wan2.1_VAE.safetensors) |

### 3. Start ComfyUI

With an NVIDIA card:

```bash
cd ComfyUI && source venv/bin/activate && python main.py
```

With no graphics card:

```bash
cd ComfyUI && source venv/bin/activate && python main.py --cpu --cache-none --disable-smart-memory --use-pytorch-cross-attention
```

`--use-pytorch-cross-attention` matters on CPU. In our tests it made each step 27% faster (1,164 s against 1,589 s at 480x272, 81 frames) and cut memory use. Changing the number of threads did not help.

### 4. Make a clip

1. Put your start picture in `ComfyUI/input/` and name it `start.png`. A 16:9 picture works best.
2. Open one of the files in `workflows/` in a text editor and change the prompt (the long English line) to describe what should happen.
3. Send it to ComfyUI:

```bash
curl -s -X POST http://127.0.0.1:8188/prompt -H 'Content-Type: application/json' -d "{\"prompt\": $(cat workflows/optimized_q4_lightning_4steps_832x480.json)}"
```

The clip is saved in `ComfyUI/output/wan/`. You can also drag the workflow file into the ComfyUI page at http://127.0.0.1:8188 and press Run.

## Settings

Optimized version:

| Setting | Value |
|---|---|
| Steps | 4 in total: steps 0 to 2 on the high noise half, steps 2 to 4 on the low noise half |
| cfg | 1 (the Lightning LoRA needs this) |
| shift | 5 |
| Sampler | euler, scheduler simple |
| LoRA strength | 1 on both halves |
| Frames | 81 at 16 frames per second (5 s). Frame count must be 4n + 1 |
| Seed | 42 |

Pure versions: 20 steps (0 to 10 on the high noise half, 10 to 20 on the low noise half), cfg 3.5, shift 8, no LoRA. Everything else is the same.

Writing the prompt: say who is in the picture, what they do, how the camera moves, and the light. One action per clip.

## Files for the pure versions

Version 2 uses the same Q4 files as the optimized version, without the two LoRA files.

Version 3 uses the original precision files. They go in `ComfyUI/models/diffusion_models/`.

| File | Size | Link |
|---|---|---|
| Original, high noise half (fp16) | 28.6 GB | [wan2.2_i2v_high_noise_14B_fp16.safetensors](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp16.safetensors) |
| Original, low noise half (fp16) | 28.6 GB | [wan2.2_i2v_low_noise_14B_fp16.safetensors](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp16.safetensors) |

In between sizes, if the original does not fit your card:

- fp8 scaled, 14.3 GB per half: [high](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors), [low](https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/diffusion_models/wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors). Change the two file names in the pure original workflow.
- Q8 GGUF, 15.4 GB per half: [all sizes](https://huggingface.co/QuantStack/Wan2.2-I2V-A14B-GGUF/tree/main). Change the two file names in the pure Q4 workflow.

You can also mix: the Lightning LoRA works on the original files too. Add the two LoRA steps from the optimized workflow and use its settings.

The model's own page: https://huggingface.co/Wan-AI/Wan2.2-I2V-A14B

## What we tried that did not work

- **The small 5B model** (Wan 2.2 TI2V 5B): 59 minutes for the same clip, but the face drifts and the colours are worse.
- **Half the frames, then filling in frames**: fast, but the result is slow motion.
- **Fewer threads, pinned cores, split attention**: no gain. Split attention ran out of memory at 81 frames.

## Credits

- Wan 2.2: https://github.com/Wan-Video/Wan2.2
- Lightning LoRA: https://github.com/ModelTC/Wan2.2-Lightning
- GGUF files: https://huggingface.co/QuantStack and https://huggingface.co/city96
- ComfyUI: https://github.com/comfyanonymous/ComfyUI
