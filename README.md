# CuttingsToGrow 🌱

An iOS app for propagating plant cuttings and swapping them with neighbors — scan a plant, see exactly where to cut, grow roots in your Digital Nursery, then trade or gift on the local Swap Map.

## Features

### 1. AR Node Scanner
Point the camera at a plant and tap **Scan**:
- **On-device identification** using Apple's Vision framework (`VNClassifyImageRequest`), whose built-in taxonomy includes plants — no network calls, no model download, runs on the Neural Engine.
- **Node overlay**: Vision saliency + contour curvature analysis localizes likely stem nodes/branch junctions and renders pulsing "cut here" markers with scissors icons over the live preview.
- Per-species guidance explains exactly where to make the snip (e.g. "1–2 cm below a node").

### 2. Safety & Viability Filter
Every scan is instantly triaged:
- **Difficulty** — Beginner (water glass on a windowsill) / Intermediate / Advanced (rooting hormone + humidity).
- **Pet toxicity** — flags toxicity to cats, dogs, rabbits, and birds (cockatiels) per ASPCA lists. Toxic species carry a 🐾 warning badge in scan results *and* on every swap listing, so adopters know before bringing a plant home.
- Water vs. soil rooting-time estimates per species.

### 3. Digital Nursery
- Log a cutting straight from a scan.
- Local push notifications remind you to **change the water every 3 days** (rot prevention) and to **check for roots** at the species' expected rooting time.
- Photo-tracked root progress; marking a cutting **rooted unlocks** swap listing.

### 4. Balcony Bounty Exchange & Swap Map
- The species database covers everyday growers too: green onions, bell peppers, tomatoes, basil, mint, rosemary — not just rare tropicals.
- MapKit Swap Map with filters for **"Free to a Good Home"** vs. **"Open to Trade"**, plus 1-for-1 trade proposals (offer a rooted cutting from your Nursery).
- **Logistics built in**: partnered public **drop-off zones** (cafés, libraries, community gardens) shown on the map, and **mail-in guidance** (damp sphagnum packing) attached to mail-in listings.

## Architecture

```
CuttingsToGrow/
├── App.swift                  # App entry + tab navigation
├── Theme/                     # Design system (botanical palette, pills, cards)
├── Models/                    # PlantSpecies, Cutting, SwapListing, DropZone
├── Services/
│   ├── PlantDatabase.swift            # Curated propagation + toxicity knowledge base
│   ├── PlantClassifierService.swift   # On-device Vision classification + node detection
│   ├── CameraService.swift            # AVFoundation live session
│   ├── NurseryStore.swift             # Local JSON persistence + reminders
│   ├── NotificationService.swift      # Water-change / root-check notifications
│   └── ExchangeStore.swift            # Listings, trades, drop zones (local-first)
└── Views/                     # Scanner, ScanResult, Nursery, SwapMap, Exchange
```

- **100% on-device ML.** `PlantClassifierService` isolates recognition behind one API, so the built-in Vision classifier can be swapped for a bundled Core ML model (e.g. a PlantNet-300K MobileNetV3 conversion) for finer-grained species coverage without touching view code.
- **Local-first stores** persist to JSON in Documents; the `ExchangeStore` API is shaped so a real backend can slot in later.
- SwiftUI throughout, iOS 17+, MapKit for the Swap Map, PhotosUI for root tracking.

## Building

Requires Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open CuttingsToGrow.xcodeproj
```

Run on a physical device for the camera scanner (the simulator has no camera).
