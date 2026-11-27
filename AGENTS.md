# For AI agents

This repo is a working recipe for Wan 2.2 image to video, plus what was learned while testing it. Read in this order and you can skip most of your own research.

1. `docs/how-image-to-video-works.md`: the mechanism, the terms, and what each speed trick costs. 5 minutes.
2. `docs/lessons-learned.md`: measured times, what failed, and the order to test things in.
3. `README.md`: install steps, download links, settings, and the three versions to choose from.
4. `workflows/`: ComfyUI API format graphs. `optimized_*` are the ones that were actually run. `pure_*` are built from stock settings and were not run by us.

## Quick decisions

- No graphics card and quality matters: `optimized_q4_lightning_4steps_832x480.json`, started with `--cpu --use-pytorch-cross-attention`. Expect about 12 hours for 5 seconds on 8 cores.
- Graphics card with 12 to 16 GB: the same optimized workflow, started without `--cpu`.
- Graphics card with 24 GB or more and quality matters most: `pure_original_fp16_20steps_832x480.json`.
- Need a preview fast: one sampling step at the real size as a timing probe, or the 480x272 workflow. Do not judge motion or light from 480x272.

## Rules that save time

- Before a long run, time one sampling step and multiply.
- Change one setting per run. Keep seed, picture and prompt fixed.
- Log each run (settings, step time, total, peak memory, output hash) as it ends.
- Judge by frame sheets, comparing the same frame numbers across runs.
- Never run two heavy jobs at once on a CPU. Cap memory per run.
- Say which numbers you measured and which you read somewhere.

## Queueing a workflow

```bash
curl -s -X POST http://127.0.0.1:8188/prompt -H 'Content-Type: application/json' -d "{\"prompt\": $(cat workflows/optimized_q4_lightning_4steps_832x480.json)}"
```

The start picture is `ComfyUI/input/start.png`. Node 9 holds the prompt, node 12 the size and frame count, nodes 13 and 14 the steps, cfg and seed. Output lands in `ComfyUI/output/wan/`.
