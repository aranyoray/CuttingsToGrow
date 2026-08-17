import Foundation

// MARK: - Reference-data enums
//
// These describe a species. They use lowercase raw values so they decode
// directly from the bundled `propagation_knowledge_base.json`. Every enum has a
// `displayName` because the raw value is for JSON, not for humans.

/// What kind of plant this is — used for grouping and the civic "regrow your
/// groceries" framing (kitchen staples + vegetables).
enum PlantCategory: String, Codable, CaseIterable {
    case houseplant
    case herb
    case kitchenStaple
    case succulent
    case vegetable

    var displayName: String {
        switch self {
        case .houseplant: return "Houseplant"
        case .herb: return "Herb"
        case .kitchenStaple: return "Kitchen Staple"
        case .succulent: return "Succulent"
        case .vegetable: return "Vegetable"
        }
    }

    var systemImage: String {
        switch self {
        case .houseplant: return "leaf.fill"
        case .herb: return "camera.macro"
        case .kitchenStaple: return "carrot.fill"
        case .succulent: return "drop.triangle.fill"
        case .vegetable: return "carrot"
        }
    }
}

/// How a cutting is taken. The trained anatomy model localises `node` /
/// `aerialRoot`; this enum records which technique the *species* uses so the
/// CutAdvisor (Phase 3) can reason about it.
enum PropagationMethod: String, Codable, CaseIterable {
    case stemCutting
    case nodeCutting
    case leafCutting
    case division
    case offset
    case waterRegrow
    case seed
    case rhizome

    var displayName: String {
        switch self {
        case .stemCutting: return "Stem Cutting"
        case .nodeCutting: return "Node Cutting"
        case .leafCutting: return "Leaf Cutting"
        case .division: return "Division"
        case .offset: return "Offset / Pup"
        case .waterRegrow: return "Regrow in Water"
        case .seed: return "From Seed"
        case .rhizome: return "Rhizome Division"
        }
    }
}

/// The medium a cutting roots in.
enum PropagationMedium: String, Codable, CaseIterable {
    case water
    case soil
    case sphagnum

    var displayName: String {
        switch self {
        case .water: return "Water"
        case .soil: return "Soil"
        case .sphagnum: return "Sphagnum Moss"
        }
    }

    var systemImage: String {
        switch self {
        case .water: return "drop.fill"
        case .soil: return "square.stack.3d.up.fill"
        case .sphagnum: return "circle.hexagongrid.fill"
        }
    }
}

/// How hard the species is to propagate — the first thing the Scan result shows.
enum Difficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }

    var summary: String {
        switch self {
        case .beginner: return "Roots easily — a great first propagation."
        case .intermediate: return "Benefits from rooting hormone or extra humidity."
        case .advanced: return "Needs rooting hormone, stable humidity, and patience."
        }
    }

    /// For sorting easiest-first.
    var rank: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1
        case .advanced: return 2
        }
    }
}

// MARK: - PlantSpecies

/// A propagatable species loaded from the bundled knowledge base.
///
/// This is a read-only *value type* (not a SwiftData model): it is reference
/// data that ships with the app, so it never needs to live in the user's mutable
/// store. The user's own cuttings (`Cutting`, a SwiftData `@Model`) link to a
/// species by `id` (its scientific name).
///
/// `toxicity` is deliberately **not** part of the knowledge-base JSON. It is
/// joined in from the separate flagship `toxicity.json` at load time (see
/// `KnowledgeBaseService`), which is why it is excluded from `CodingKeys` and
/// defaults to `nil`.
struct PlantSpecies: Identifiable, Codable, Hashable {
    /// The scientific name is stable and unique, so it doubles as the id/link key.
    var id: String { scientificName }

    let commonName: String
    let scientificName: String
    let category: PlantCategory
    let propagationMethod: PropagationMethod
    let difficulty: Difficulty
    let preferredMedium: PropagationMedium
    let needsRootingHormone: Bool
    /// True when a cutting roots best with an aerial root attached (e.g. monstera).
    /// The CutAdvisor uses this in Phase 3.
    let requiresAerialRoot: Bool
    /// Typical days to root in water; `nil` when water propagation isn't advised.
    let rootTimeWaterDays: Int?
    /// Typical days to root in soil; `nil` when not applicable.
    let rootTimeSoilDays: Int?
    let cutLocationDescription: String
    let notes: String
    /// True when a horticulture claim in this entry is uncertain and should be checked.
    let verify: Bool

    /// Joined from `toxicity.json` after decoding (see `KnowledgeBaseService`).
    var toxicity: ToxicityInfo? = nil

    private enum CodingKeys: String, CodingKey {
        case commonName, scientificName, category, propagationMethod, difficulty,
             preferredMedium, needsRootingHormone, requiresAerialRoot,
             rootTimeWaterDays, rootTimeSoilDays, cutLocationDescription, notes, verify
    }

    /// Toxicity info, or a safe "unknown/verify" fallback if none was joined.
    var toxicityOrUnknown: ToxicityInfo {
        toxicity ?? .unknown(for: self)
    }

    /// Typical rooting time for a given medium, in days (nil if not applicable).
    func rootTimeDays(in medium: PropagationMedium) -> Int? {
        switch medium {
        case .water: return rootTimeWaterDays
        case .soil, .sphagnum: return rootTimeSoilDays
        }
    }

    /// A short, friendly rooting-time phrase for the UI.
    var rootTimeSummary: String {
        if let water = rootTimeWaterDays {
            return "~\(water) days in water"
        } else if let soil = rootTimeSoilDays {
            return "~\(soil) days in soil"
        } else {
            return "Varies"
        }
    }
}
