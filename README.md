# Cuttings Garden 🌱

A local, waste-reducing, pet-safe plant-and-food sharing app for iOS.
**Congressional App Challenge 2026.**

Photograph a plant → it's identified and flagged for pet toxicity → an on-device
model marks **where to cut** and **which leaves to trim** directly on your photo →
track the cutting as it roots in your **Digital Nursery** → once it has roots,
gift or trade it on the local **Swap Map**.

> The app runs on still photos + an on-device Core ML object-detection model —
> **no AR**. The whole capture → detect → overlay → advise → save flow is
> demoable in the iOS Simulator on bundled sample photos, because the vision
> features sit behind protocols with deterministic **Mock** implementations.

## Why it matters (civic impact)

- 💸 **Save money & cut food waste** — regrow green onion, celery, lettuce, and
  herbs from kitchen scraps.
- 🤝 **Neighbourhood mutual aid** — a local free/trade network for cuttings.
- ♻️ **Less plant waste** — propagate instead of buy.
- 🐾 **Pet safety (flagship)** — warn people about toxic plants *before* one
  reaches a cat, dog, or small pet.

## Design principle: perception vs. reasoning

The trained model only ever reports **anatomy** — `node`, `aerialRoot`,
`deadOrYellowingLeaf` — each with a confidence score. All "cut here / trim these"
**reasoning lives in app code** (`CutAdvisor` + the knowledge base), never in the
model. This keeps the model small and trainable by one student, and keeps the
advice explainable. Detector confidence is always shown; the app never implies
certainty the model doesn't have.

## Architecture

```
CuttingsToGrow/                 (Xcode target)
  App/            entry point, SwiftData container, root TabView
  Models/         value types (PlantSpecies, ToxicityInfo, AnatomyDetection,
                  CutGuidance) + SwiftData @Model (Cutting, RootPhoto, SwapListing)
  Services/
    KnowledgeBase/  loads the propagation knowledge base, joins toxicity
    Toxicity/       loads the flagship pet-toxicity dataset
    Persistence/    SwiftData container + first-launch seeding
  Shared/         design system, reusable views, JSON + sample-image loaders
  Features/       Scan / Nursery / SwapMap screens
  Resources/      propagation_knowledge_base.json, toxicity.json,
                  seed_listings.json, SampleImages/
Docs/             LEARN.md, make_samples.py (MODEL_TRAINING.md & DEMO_SCRIPT.md
                  land in later phases)
```

- **Two swappable model seams.** `PlantIdentificationService` and
  `PlantAnatomyDetector` are protocols with a Mock default and a real
  implementation that slots in later — dependency inversion, so a demo can never
  be blocked by an unfinished model.
- **Local-first, no backend.** Reference data (species, toxicity) ships as JSON;
  user data (cuttings, photos, listings) uses **SwiftData**. Swap listings are
  seeded from a bundled dataset. A multi-user backend is explicitly future work.
- **Honest data.** Facts we couldn't confirm are flagged `"verify": true` in the
  JSON and shown as an amber "unverified" state, never as "safe."

Stack: Swift + SwiftUI (iOS 17+), SwiftData, Core ML + Vision (Phase 3),
AVFoundation + PhotosUI (Phase 2), MapKit (Phase 4), UserNotifications (Phase 1).

## Build & run

Requires Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
cd CuttingsToGrow            # the repo root (this folder)
xcodegen generate
open CuttingsToGrow.xcodeproj
```

Then pick an iPhone Simulator and run. Phase 0 is fully explorable in the
Simulator — no device needed. (Live camera capture, added in Phase 2, is the only
device-only piece.)

## Build status (phased)

The app is built in strict phases; each one compiles, runs, and demos on its own.

- [x] **Phase 0 — Scaffold:** SwiftData container, 3-tab shell, design system,
      all datasets + sample images loading, seed/preview data, polished empty
      states.
- [x] **Phase 1 — Digital Nursery:** add/edit/delete cuttings, status + rooting
      timeline, water-change & root-check reminders, and a root-progress photo
      timeline (the "rooted unlocks swap" mechanic). A complete app on its own.
- [ ] Phase 2 — Scan & Learn (species ID + pet-toxicity flags)
- [ ] Phase 3 — Cut & Trim Guide (on-device anatomy model + overlay)
- [ ] Phase 4 — Swap Map (MapKit, filters, gift/trade)
- [ ] Phase 5 — Polish & demo assets

See [`Docs/LEARN.md`](Docs/LEARN.md) for the plain-English architecture write-up.
