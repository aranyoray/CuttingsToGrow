import Foundation

/// Curated propagation knowledge base. Maps on-device Vision classifier labels
/// to species records with cutting guidance, difficulty, and pet-toxicity data
/// (toxicity sourced from ASPCA toxic/non-toxic plant lists).
enum PlantDatabase {
    static func species(id: String) -> PlantSpecies? {
        all.first { $0.id == id }
    }

    /// Match an on-device classifier label (e.g. "golden pothos", "ivy",
    /// "scallion") to a species record.
    static func match(classifierLabel: String) -> PlantSpecies? {
        let label = classifierLabel.lowercased()
        return all.first { species in
            species.classifierKeywords.contains { label.contains($0) }
                || label.contains(species.commonName.lowercased())
        }
    }

    static let all: [PlantSpecies] = [
        PlantSpecies(
            commonName: "Golden Pothos",
            scientificName: "Epipremnum aureum",
            category: .houseplant,
            difficulty: .beginner,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .water,
            waterRootDays: 7...14,
            soilRootDays: 21...35,
            cuttingGuidance: "Cut 1–2 cm below a node (the brown bump where leaf meets vine). Each cutting needs at least one node and one leaf. Aerial root nubs root fastest.",
            classifierKeywords: ["pothos", "epipremnum", "devil's ivy", "devils ivy"]
        ),
        PlantSpecies(
            commonName: "Monstera Deliciosa",
            scientificName: "Monstera deliciosa",
            category: .houseplant,
            difficulty: .beginner,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .water,
            waterRootDays: 14...28,
            soilRootDays: 28...42,
            cuttingGuidance: "Cut just below a node with an aerial root attached. Include one leaf. Submerge the node and aerial root, keep the leaf dry.",
            classifierKeywords: ["monstera", "swiss cheese", "split-leaf philodendron"]
        ),
        PlantSpecies(
            commonName: "Heartleaf Philodendron",
            scientificName: "Philodendron hederaceum",
            category: .houseplant,
            difficulty: .beginner,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .water,
            waterRootDays: 10...21,
            soilRootDays: 21...35,
            cuttingGuidance: "Snip below a node, leaving 2–3 leaves per cutting. Remove the lowest leaf so the node sits clean in water.",
            classifierKeywords: ["philodendron", "heartleaf"]
        ),
        PlantSpecies(
            commonName: "Snake Plant",
            scientificName: "Dracaena trifasciata",
            category: .houseplant,
            difficulty: .intermediate,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: false),
            preferredMedium: .water,
            waterRootDays: 30...60,
            soilRootDays: 42...70,
            cuttingGuidance: "Cut a healthy leaf into 8–10 cm sections. Mark which end faced down — leaf sections only root from the basal (lower) edge.",
            classifierKeywords: ["snake plant", "sansevieria", "mother-in-law's tongue", "dracaena trifasciata"]
        ),
        PlantSpecies(
            commonName: "Spider Plant",
            scientificName: "Chlorophytum comosum",
            category: .houseplant,
            difficulty: .beginner,
            toxicity: .safe,
            preferredMedium: .water,
            waterRootDays: 7...14,
            soilRootDays: 14...21,
            cuttingGuidance: "Snip the plantlets (spiderettes) from the runner stems. Plantlets with visible root nubs can go straight to soil.",
            classifierKeywords: ["spider plant", "chlorophytum", "airplane plant"]
        ),
        PlantSpecies(
            commonName: "English Ivy",
            scientificName: "Hedera helix",
            category: .houseplant,
            difficulty: .beginner,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .water,
            waterRootDays: 14...21,
            soilRootDays: 21...42,
            cuttingGuidance: "Take 10–15 cm tip cuttings just below a node. Strip leaves from the lower half before placing in water.",
            classifierKeywords: ["ivy", "hedera"]
        ),
        PlantSpecies(
            commonName: "Jade Plant",
            scientificName: "Crassula ovata",
            category: .succulent,
            difficulty: .intermediate,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .soil,
            waterRootDays: nil,
            soilRootDays: 14...28,
            cuttingGuidance: "Cut a stem or single leaf and let the wound callus for 2–3 days before placing on dry succulent mix. Do not propagate in water — it rots.",
            classifierKeywords: ["jade", "crassula", "money plant"]
        ),
        PlantSpecies(
            commonName: "Echeveria",
            scientificName: "Echeveria spp.",
            category: .succulent,
            difficulty: .intermediate,
            toxicity: .safe,
            preferredMedium: .soil,
            waterRootDays: nil,
            soilRootDays: 21...42,
            cuttingGuidance: "Twist a healthy leaf cleanly from the stem (no tearing). Callus 3 days, then lay on dry soil and mist weekly.",
            classifierKeywords: ["echeveria", "succulent", "hens and chicks"]
        ),
        PlantSpecies(
            commonName: "Fiddle Leaf Fig",
            scientificName: "Ficus lyrata",
            category: .houseplant,
            difficulty: .advanced,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .water,
            waterRootDays: 30...60,
            soilRootDays: 42...90,
            cuttingGuidance: "Take a 30 cm stem cutting with 2–3 leaves. Dip in rooting hormone and keep humidity high. Sap is irritating — wear gloves.",
            classifierKeywords: ["fiddle", "ficus lyrata", "fig"]
        ),
        PlantSpecies(
            commonName: "Rubber Plant",
            scientificName: "Ficus elastica",
            category: .houseplant,
            difficulty: .advanced,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .sphagnum,
            waterRootDays: 30...60,
            soilRootDays: 42...60,
            cuttingGuidance: "Air-layering or a hormone-dipped tip cutting in moist sphagnum works best. Blot the milky sap before potting.",
            classifierKeywords: ["rubber plant", "ficus elastica"]
        ),
        // Kitchen staples — the Balcony Bounty
        PlantSpecies(
            commonName: "Green Onion",
            scientificName: "Allium fistulosum",
            category: .kitchenStaple,
            difficulty: .beginner,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .water,
            waterRootDays: 3...7,
            soilRootDays: 7...10,
            cuttingGuidance: "Keep the bottom 3 cm with the root plate intact. Stand upright in a glass with roots submerged; regrows in days.",
            classifierKeywords: ["green onion", "scallion", "spring onion", "allium"]
        ),
        PlantSpecies(
            commonName: "Bell Pepper",
            scientificName: "Capsicum annuum",
            category: .kitchenStaple,
            difficulty: .intermediate,
            toxicity: PetToxicity(cats: false, dogs: false, rabbits: false, birds: false),
            preferredMedium: .soil,
            waterRootDays: nil,
            soilRootDays: 7...14,
            cuttingGuidance: "Best grown from saved seeds; rinse, dry 2 days, then sow 0.5 cm deep in warm seed-starting mix. Foliage (not fruit) is toxic to pets.",
            classifierKeywords: ["bell pepper", "capsicum", "pepper"]
        ),
        PlantSpecies(
            commonName: "Basil",
            scientificName: "Ocimum basilicum",
            category: .herb,
            difficulty: .beginner,
            toxicity: .safe,
            preferredMedium: .water,
            waterRootDays: 7...14,
            soilRootDays: 14...21,
            cuttingGuidance: "Cut a 10 cm stem just below a leaf pair. Strip the lower leaves and keep two top pairs. Roots in a sunny windowsill glass.",
            classifierKeywords: ["basil", "ocimum"]
        ),
        PlantSpecies(
            commonName: "Mint",
            scientificName: "Mentha spp.",
            category: .herb,
            difficulty: .beginner,
            toxicity: .safe,
            preferredMedium: .water,
            waterRootDays: 5...10,
            soilRootDays: 10...14,
            cuttingGuidance: "Cut below a node on a healthy runner. Mint roots aggressively — almost any node will take.",
            classifierKeywords: ["mint", "mentha", "peppermint", "spearmint"]
        ),
        PlantSpecies(
            commonName: "Rosemary",
            scientificName: "Salvia rosmarinus",
            category: .herb,
            difficulty: .intermediate,
            toxicity: .safe,
            preferredMedium: .soil,
            waterRootDays: 21...42,
            soilRootDays: 21...35,
            cuttingGuidance: "Take 10 cm semi-woody tip cuttings. Strip lower needles, dip in rooting hormone, and keep barely moist — overwatering kills rosemary cuttings.",
            classifierKeywords: ["rosemary", "rosmarinus"]
        ),
        PlantSpecies(
            commonName: "Tomato",
            scientificName: "Solanum lycopersicum",
            category: .kitchenStaple,
            difficulty: .beginner,
            toxicity: PetToxicity(cats: true, dogs: true, rabbits: true, birds: true),
            preferredMedium: .water,
            waterRootDays: 7...10,
            soilRootDays: 10...14,
            cuttingGuidance: "Snap off a sucker (the shoot between main stem and branch) 10–15 cm long. It roots in water within a week. Vines are toxic to pets.",
            classifierKeywords: ["tomato", "solanum"]
        )
    ]
}
