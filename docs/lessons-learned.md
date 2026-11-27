# Lessons learned running Wan 2.2 on a machine with no graphics card

What we measured, what failed, and what we would do first next time. Read this before you start testing, so you do not repeat the slow parts.

Machine: 8 CPU cores (AMD EPYC, AVX2, no AVX-512), 31 GB RAM, no graphics card, ComfyUI with `--cpu`. Model: Wan 2.2 I2V 14B, GGUF Q4_K_M, Lightning 4 step LoRA, cfg 1, shift 5.

Each line says if it is **measured** by us or a **lead** from reading that we have not confirmed.

## Numbers

| Run | Size | Time | Peak RAM | Verdict |
|---|---|---|---|---|
| 14B, 4 steps | 832x480, 81 frames | 11 h 53 min | 25.9 GB | Best result by far |
| 14B, 4 steps, then enlarged x4 | 480x272, 81 frames | about 2 h 20 min | about 20 GB | Motion stalls for about 1.4 s, glow and light rays missing |
| 14B, 4 steps, then RIFE x2 and enlarged | 480x272, 41 frames | 58 + 8 min | 20.2 GB | Looks fine but is slow motion |
| 5B with FastWan LoRA | 832x480, 81 frames | 59 min | 16.7 GB | Face drifts, colours worse |

Seconds per sampling step, one step probes:

| Setting | 832x480, 17 frames | 480x272, 81 frames |
|---|---|---|
| Default (sub-quadratic attention) | 1,098 | 1,589 |
| `--use-pytorch-cross-attention` | 863 | 1,164 |
| `--use-split-cross-attention` | 1,207 | out of memory at 29.7 GB |
| 6 threads | 1,189 | |
| 4 threads | 1,771 | |
| 8 threads pinned to cores | 1,087 | |

## What we would tell ourselves on day one

1. **Sampling is about 90 percent of the time.** Loading, text encoding, VAE and upscaling are small. Only work that cuts steps, tokens or cost per step matters. (measured)
2. **Use `--use-pytorch-cross-attention` on CPU.** 21 to 27 percent faster and much less memory. It was the only flag that helped. (measured)
3. **Do not tune threads.** The default of one thread per core is already best. Pinning changes under 1 percent, fewer threads is slower. (measured)
4. **Quality lives at the trained resolution.** The stall in motion and the missing glow at 480x272 were already in the raw clip before any upscaling. An upscaler cannot bring back what was never drawn. (measured)
5. **A smaller model is not a shortcut.** The 5B model was 12 times faster and the result was rejected on sight. (measured)
6. **Fewer frames then interpolation gives slow motion.** The model draws the same action over fewer frames, and filling in frames stretches it. (measured)
7. **Probe before you commit.** Run one sampling step at the real size and stop. One step tells you the time of the whole run (steps x step time, plus a few minutes of loading). We wasted an 11 hour run finding out what a 20 minute probe would have shown.
8. **Change one thing per run and keep seed, picture and prompt fixed.** Otherwise you cannot tell what caused a difference.
9. **Write every run in a results table as it finishes**: settings, step time, total time, peak memory, the file's hash. Memory of what was tried fades in hours.
10. **Look at the frames, not only at the clip.** Extract every frame, lay them in a sheet, and compare the same frame numbers across runs. The stall was obvious in a frame sheet and easy to miss in playback.
11. **Cap memory per run.** One out of memory run killed the job runner for everything else on the machine. Start each run in its own memory limited scope (for example `systemd-run --scope -p MemoryMax=24G`).
12. **Do not run two heavy jobs at once on CPU.** A render started next to a Wan run timed out twice. Lowering the Wan job's priority with `nice` did not help. Queue them.
13. **Quantization does not make CPU runs faster.** Q4 is about memory and disk. (lead, consistent with what we saw)
14. **Cost grows faster than frame count.** At the same picture size, 81 frames did about half the work per second of 17 frames. (measured, rough)

## Things worth trying next, in order

These are leads from reading. None is confirmed by us yet.

1. A middle size, 576x320 or 640x368, with 49 frames. Closer to the trained size, far fewer tokens than 832x480.
2. Lower strength (0.6 to 0.8) on the high noise LoRA, or a newer Lightning LoRA, to fix slow motion.
3. 3 steps (2 high, 1 low) in place of 4.
4. Video to video repaint: render rough motion some other way (3D, a simple animation), then let only the low noise expert repaint it in 2 steps. About half the cost, and the motion is under your control.
5. Not worth the time on a CPU without AVX-512: bf16, OpenVINO, IPEX, step caching.

## Prompt and picture tips

- The start picture should be the same shape as the output (16:9 for 832x480). Cropping changes the framing.
- Describe the action, the camera and the light in one or two sentences. One action per clip.
- With the Lightning LoRA at cfg 1 the negative prompt has no effect. Put what you want in the positive prompt.
- Keep the seed fixed while testing settings. Change the seed only when you want a different take.
