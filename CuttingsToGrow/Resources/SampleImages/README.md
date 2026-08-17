# Sample Images

These four PNGs let the **Scan → identify → cut/trim** flow run end-to-end in the
iOS Simulator, which has no camera. The Mock detectors return deterministic
results keyed to these images, so the whole feature is demoable before the
trained Core ML model exists.

## ⚠️ They are placeholders

`pothos.png`, `monstera.png`, `philodendron.png`, and `basil.png` are
**procedurally generated** stand-ins (a stem with node dots and leaves). They are
*not* real photographs.

**Before recording the demo video, replace each file with a real, well-lit photo
of that species** — keep the same filename and the app picks it up automatically
(the mapping lives in `sample_images_manifest.json`). Real photos make the
identification and cut-guide overlay far more convincing to judges.

## Adding more

1. Drop a `.png`/`.jpg` into this folder.
2. Add an entry to `sample_images_manifest.json` with its `fileName` (no
   extension) and the `speciesID` (the scientific name from
   `propagation_knowledge_base.json`).

The generator script that produced the placeholders is checked in under
`Docs/` for reference (`make_samples.py`), but you should not need it once you
have real photos.
