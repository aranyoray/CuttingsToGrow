import Foundation

enum PropagationDifficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var summary: String {
        switch self {
        case .beginner: return "Roots easily in plain water — great first propagation."
        case .intermediate: return "Benefits from rooting hormone or extra humidity."
        case .advanced: return "Needs rooting hormone, stable humidity, and patience."
        }
    }
}

enum PropagationMedium: String, Codable, CaseIterable {
    case water = "Water"
    case soil = "Soil"
    case sphagnum = "Sphagnum Moss"
}

struct PetToxicity: Codable, Hashable {
    let cats: Bool
    let dogs: Bool
    let rabbits: Bool
    let birds: Bool

    var isToxicToAny: Bool { cats || dogs || rabbits || birds }

    var affectedPets: [String] {
        var pets: [String] = []
        if cats { pets.append("Cats") }
        if dogs { pets.append("Dogs") }
        if rabbits { pets.append("Rabbits") }
        if birds { pets.append("Birds (e.g. cockatiels)") }
        return pets
    }

    static let safe = PetToxicity(cats: false, dogs: false, rabbits: false, birds: false)
    static let toxicToAll = PetToxicity(cats: true, dogs: true, rabbits: true, birds: true)
}

enum PlantCategory: String, Codable, CaseIterable {
    case houseplant = "Houseplant"
    case kitchenStaple = "Kitchen Staple"
    case herb = "Herb"
    case succulent = "Succulent"
}

/// A propagatable species with everything the scanner needs to triage it.
struct PlantSpecies: Identifiable, Codable, Hashable {
    var id: String { scientificName }
    let commonName: String
    let scientificName: String
    let category: PlantCategory
    let difficulty: PropagationDifficulty
    let toxicity: PetToxicity
    let preferredMedium: PropagationMedium
    let waterRootDays: ClosedRange<Int>?
    let soilRootDays: ClosedRange<Int>
    let cuttingGuidance: String
    /// Vision classifier identifiers (lowercased) that map to this species.
    let classifierKeywords: [String]
}

extension ClosedRange: Codable where Bound: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let lower = try container.decode(Bound.self)
        let upper = try container.decode(Bound.self)
        self = lower...upper
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lowerBound)
        try container.encode(upperBound)
    }
}
