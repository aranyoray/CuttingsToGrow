# LEARN.md — Cuttings Garden, explained

This is the running "explain it to a judge" document. It grows one phase at a
time. If you can explain everything in here in your own words, you can defend the
whole app — including the machine-learning part.

> **Status: Phase 0 (Scaffold) complete.** The app compiles and runs in the
> Simulator with three tabs, a full local dataset layer, a design system, and
> polished empty states. No camera or ML yet — those arrive in later phases,
> behind interfaces that already shape the code.

---

## 1. The problem, in one breath

People throw away plants and kitchen scraps that could be regrown for free, and
every year pets are poisoned by common houseplants. **Cuttings Garden** turns
propagation into a local, waste-reducing, pet-safe sharing network: photograph a
plant → identify it and flag pet toxicity → an on-device model shows *where to
cut* → track the cutting as it roots → once it has roots, gift or trade it on a
local Swap Map.

Four civic angles, threaded through the UI copy:

- **Save money & food waste** — regrow green onion, celery, lettuce, herbs.
- **Neighbourhood mutual aid** — a local free/trade network for cuttings.
- **Less plant waste** — propagate instead of buy.
- **Pet safety** — the flagship: warn people *before* a plant reaches a pet.

## 2. The single most important idea: perception vs. reasoning

The app draws a hard line between two kinds of work:

| | **Perception** (the model) | **Reasoning** (app code) |
|---|---|---|
| Job | Find anatomy in a photo | Decide what to *do* about it |
| Output | Boxes: `node`, `aerialRoot`, `deadOrYellowingLeaf` | "Cut ~1 cm below this node; trim those 2 leaves" |
| Lives in | `PlantAnatomyDetector` (Phase 3) | `CutAdvisor` + the knowledge base (Phase 3) |

The model **never** outputs "cut here." It only reports what it sees, with a
confidence number. The app turns anatomy + the species' profile into advice.

Why this matters for the demo:

- It's **honest** — we show the model's confidence and never fake certainty.
- It's **trainable by one person** — three simple anatomy classes instead of a
  giant "cutting-advice" model.
- It's **explainable** — the "where to cut" rules are plain Swift you wrote, not
  a black box.

The contract both sides agree on is already in the code: see
`Models/AnatomyDetection.swift`. The trained model and the app are built to that
same struct, so the model can land later without touching feature code.

## 3. The two "model seams" (dependency inversion)

Two things the app depends on are defined as **protocols** with a **Mock**
default and a real implementation that slots in later:

1. `PlantIdentificationService` — "what species is this?" (Phase 2)
2. `PlantAnatomyDetector` — "where are the nodes/leaves?" (Phase 3)

The whole app is built and demoed against the Mocks, which return deterministic
results on the bundled sample photos — so the entire flow works in the Simulator
*before* the real model exists. When the trained `PlantAnatomy.mlmodel` is ready,
`CoreMLAnatomyDetector` conforms to the same protocol and drops in.

This pattern — depend on an interface, not a concrete class — is called
**dependency inversion**. It's the reliability backbone: the demo can never be
blocked by an unfinished model.

> Phase 0 note: the protocols and Mocks are introduced in Phases 2–3 (we don't
> build ahead). The *value-type contract* they'll produce (`AnatomyDetection`,
> `CutGuidance`) already exists so the shape is locked in.

## 4. Where the data lives — and why two kinds of storage

The app deliberately uses **two** storage strategies, and being able to say why
is a great judge answer:

- **Reference data ships as JSON** and is loaded into value types
  (`PlantSpecies`, `ToxicityInfo`). It's read-only, the same for everyone, and
  never changes at runtime — so it doesn't belong in a mutable database.
  - `Resources/propagation_knowledge_base.json` — 31 species: method, where to
    cut, difficulty, water/soil rooting time, rooting-hormone flag, notes.
  - `Resources/toxicity.json` — the flagship pet-safety dataset, kept **separate**
    so it's easy to audit and cite.
- **User data uses SwiftData** (`@Model` classes: `Cutting`, `RootPhoto`,
  `SwapListing`). It's created by the user, it changes, and it must persist
  between launches — exactly what a local database is for.

### The toxicity "join"

The knowledge base says *how to grow* a plant; the toxicity file says *whether
it's dangerous*. At load time, `KnowledgeBaseService` matches them by scientific
name and attaches the right `ToxicityInfo` to each `PlantSpecies`. Two clean
datasets on disk, one rich object in memory.

### Honesty flag

We didn't invent facts. Anything we weren't sure about carries `"verify": true`
in the JSON (11 toxicity entries, 1 horticulture note as of Phase 0), and the UI
shows an amber "unverified" state instead of a green "safe." **Unknown is treated
as caution, never as safe.**

## 5. What's actually on screen in Phase 0

- **Scan tab** — introduces the 3-step flow and *proves the data loaded*: it
  shows the four bundled sample photos and live counts (species / toxicity
  records / sample photos).
- **Nursery tab** — a polished empty state, with the SwiftData query already
  wired up. Becomes fully functional in Phase 1.
- **Swap tab** — the six seeded demo listings, each already carrying the
  pet-safety badge. The interactive map comes in Phase 4.

## 6. File-by-file map

```
CuttingsToGrow/
  App/            CuttingsGardenApp (entry + container), RootView (tabs + seeding)
  Models/         PlantSpecies, ToxicityInfo (value types)
                  Cutting, RootPhoto, SwapListing (SwiftData @Model)
                  AnatomyDetection, CutGuidance (the model I/O contract)
                  PreviewData (in-memory sample data for previews)
  Services/
    KnowledgeBase/  loads the knowledge base, joins toxicity
    Toxicity/       loads the flagship toxicity dataset
    Persistence/    builds the SwiftData container, seeds demo listings
  Shared/         Theme (design system), Components (reusable views),
                  BundleLoader (JSON helper), SampleImageLibrary
  Features/       Scan / Nursery / SwapMap screens
  Resources/      the JSON datasets + SampleImages/
```

## 7. Three things to be ready to explain

1. **"The model finds anatomy; the app decides the cut."** Point at
   `AnatomyDetection.swift` (only `node` / `aerialRoot` / `deadOrYellowingLeaf`)
   and explain the `CutAdvisor` will do the reasoning.
2. **"Mocks mean the demo never depends on the model."** Explain dependency
   inversion and why the whole flow runs in the Simulator on bundled photos.
3. **"Two datasets, joined by scientific name — and we flag what we're unsure
   of."** Explain JSON-for-reference vs SwiftData-for-user-data, and the
   `verify` honesty flag.

---

*Next: Phase 1 — the Digital Nursery becomes fully functional (add cuttings,
water-change reminders, root-progress photo timeline). That phase alone is a
complete, competition-eligible app.*
