# LEARN.md — Cuttings Garden, explained

This is the running "explain it to a judge" document. It grows one phase at a
time. If you can explain everything in here in your own words, you can defend the
whole app — including the machine-learning part.

> **Status: Phase 1 (Digital Nursery) complete.** On top of the Phase 0 scaffold,
> the Nursery tab is now a complete, competition-eligible app on its own: add /
> edit / delete cuttings, track status and a rooting timeline, get water-change
> and root-check reminders, and log a photo timeline that marks a cutting rooted.
> No camera or ML yet — those arrive in later phases, behind interfaces that
> already shape the code.

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

## 8. Phase 1 — the Digital Nursery (fully functional)

This is the first tab that actually *does* something, and it's the app's heart.
It's built entirely on SwiftData — no ML, no network.

**Create / read / update / delete, the SwiftData way.**
- **Add** (`AddCuttingView`): pick a species from the searchable, category-grouped
  `SpeciesPickerView`, name it, choose water/soil, add a note → a `Cutting` is
  `context.insert`ed.
- **Read** (`NurseryView`): an `@Query(sort: \Cutting.dateStarted, order: .reverse)`
  keeps the list live — insert or delete anywhere and the list just updates.
- **Update** (`EditCuttingView`, `CuttingDetailView`): edits go straight onto the
  `@Model` object. `EditCuttingView` edits *local copies* and applies them on
  Save, so Cancel genuinely discards.
- **Delete**: from a swipe on the list or the detail screen. Detail dismisses
  first and deletes on the next runloop tick, so the view stops observing the
  model before it disappears (a real SwiftData gotcha worth knowing).

**The photo timeline (a relationship).** `Cutting` has
`@Relationship(deleteRule: .cascade) var rootPhotos: [RootPhoto]`. Adding a photo
via `PhotosPicker` inserts a `RootPhoto`, links it to its cutting, and SwiftData
maintains the inverse automatically. Delete a cutting and its photos cascade
away. Photo bytes use `@Attribute(.externalStorage)` so they live as files, not
database bloat.

**The "rooted unlocks swap" mechanic.** Adding a root photo asks *"does it have
roots yet?"* Answering yes flips `status` to `rooted`, which is exactly the gate
the Swap Map (Phase 4) checks (`Cutting.canBeListed`).

**Reminders that respect the model.** `NotificationService` schedules a repeating
water-change nudge (water cuttings) and a one-time root-check nudge at the
species' expected rooting time. Everything is keyed to `cutting.id`, so becoming
rooted or being deleted cancels the right reminders. Permission is requested when
you add your first cutting — a concrete reason, not a cold prompt. (In DEBUG the
intervals are compressed to seconds so a reminder can actually fire on camera.)

Three things to be ready to explain here:
1. **`@Query` is live** — why the list updates itself with no manual refresh.
2. **The cascade relationship** — one line (`deleteRule: .cascade`) makes photos
   follow their cutting.
3. **Reminders keyed to id** — how scheduling and cancelling stay in lockstep
   with the cutting's status.

---

*Next: Phase 2 — Scan & Learn. A captured/picked photo runs through
`PlantIdentificationService` (Mock default) to a species result with the bold
pet-safety flags, and "Add to Nursery" wires straight into Phase 1.*
