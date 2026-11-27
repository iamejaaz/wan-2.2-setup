# Example prompts for image to video

The start picture already shows who is in the scene and what it looks like. The prompt's job is to say **what happens next**. Do not spend the prompt describing the picture again in detail.

## The pattern

One or two sentences, in this order:

1. **Who**: a short name for the subject, enough for the model to know which thing you mean ("a little girl in a yellow dress", "the red car").
2. **Action**: one clear action with a start and an end ("turns her head and smiles").
3. **Small motion**: what else moves a little (hair, leaves, steam, cloth).
4. **Camera**: one move, or say it stays still ("slow push in", "camera stays fixed").
5. **Light and style**: only what should stay or change ("warm golden light", "3D animated film style").

A clip is 5 seconds. One action fits. Two actions get rushed or one is dropped.

## Examples

The first prompt is the one we ran for our own tests. The others follow the same pattern and are starting points, not tested results.

### Characters

```text
A little girl in a yellow dress stands in a sunny flower garden, she smiles, tilts her head and reaches gently toward a pink tulip, soft breeze moves her hair and the flowers, warm golden light, gentle camera push in, 3D animated film style
```

```text
A small fox sits on the grass, it looks up, its ears twitch and it wags its tail once, grass sways in the breeze, camera stays fixed, soft morning light, 3D animated film style
```

```text
An old man at a wooden desk looks up from his book and slowly smiles at the camera, dust floats in the window light, slow push in toward his face, warm indoor light, realistic film look
```

```text
A woman in a red coat walks toward the camera along a wet street, her coat and hair move with each step, the camera moves backward at her speed, neon signs reflect on the ground, night, cinematic
```

### Camera moves

```text
The camera slowly circles to the right around the statue, the statue does not move, clouds drift in the sky, soft daylight
```

```text
Slow pull back from the cup on the table to show the whole kitchen, steam rises from the cup, morning light through the window
```

```text
The camera tilts up from the feet of the robot to its face, small lights on its chest blink, dark workshop, blue rim light
```

### Nature and places

```text
Waves roll in and break on the rocks, spray flies up, seabirds cross the sky, camera stays fixed, golden sunset light
```

```text
Snow falls gently over the village, smoke rises from the chimneys, a window light flickers, slow push in, blue evening light
```

```text
Wind moves through the wheat field in long waves, clouds pass quickly overhead, the camera glides forward low over the wheat, bright midday sun
```

### Objects and products

```text
The watch turns slowly on the stand, light glides across the glass and the metal, dark background, camera stays fixed, studio lighting
```

```text
Hot coffee is poured into the glass cup, the coffee swirls and steam rises, the camera stays fixed at table height, soft warm light
```

### Mood and effects

```text
The candle flame flickers and the shadows on the wall move with it, a curtain moves slightly, camera stays fixed, dark room
```

```text
Fireflies rise from the grass around the child, the child looks up in wonder, slow push in, deep blue night with warm glowing points
```

## What works and what does not

| Do | Avoid |
|---|---|
| One action per clip | A list of three things to do in 5 seconds |
| Name the camera move, or say it stays fixed | Leaving the camera out, then getting a random drift |
| Verbs of real motion: walks, turns, reaches, pours | "is beautiful", "looks amazing": nothing to animate |
| Mention small motion (hair, leaves, steam) for life | A fully still scene: the model may freeze the whole frame |
| Say the style when the picture is stylised ("3D animated film style", "anime", "watercolour") | Asking for a different style than the picture has |
| Keep the seed and change one phrase at a time | Rewriting the whole prompt between tries |

## Notes for the two versions

- **Optimized version (Lightning LoRA, cfg 1):** the negative prompt does nothing. If you do not want something, do not mention it at all, and describe what you want in its place. Motion comes out a little slow, so use stronger verbs ("runs" over "moves").
- **Pure versions (cfg 3.5):** the negative prompt works. The workflows keep Wan's own default negative prompt, which is in Chinese and lists the usual faults (blur, bad hands, still frame, subtitles). Leave it in.

## Fixing common problems with the prompt

| Problem | Try |
|---|---|
| Nothing moves | Add a clear verb and a small motion, add "camera push in" |
| Too slow | Stronger verb, shorter action, or lower the high noise LoRA strength to 0.7 |
| The face changes | Smaller action, keep the face toward the camera, say "camera stays fixed" |
| Camera wanders | Say "camera stays fixed" or name one move |
| Something new appears | Remove words that name things not in the picture |
