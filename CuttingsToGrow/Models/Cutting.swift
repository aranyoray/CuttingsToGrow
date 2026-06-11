import Foundation

enum CuttingStage: String, Codable, CaseIterable {
    case freshlyCut = "Freshly Cut"
    case rooting = "Rooting"
    case rooted = "Rooted"
    case listed = "Listed for Swap"
    case swapped = "Swapped"

    var systemImage: String {
        switch self {
        case .freshlyCut: return "scissors"
        case .rooting: return "drop"
        case .rooted: return "leaf"
        case .listed: return "tag"
        case .swapped: return "hands.clap"
        }
    }
}

/// A cutting living in the user's Digital Nursery.
struct Cutting: Identifiable, Codable, Hashable {
    let id: UUID
    var speciesID: String
    var nickname: String
    var medium: PropagationMedium
    var cutDate: Date
    var stage: CuttingStage
    var lastWaterChange: Date?
    var rootPhotoData: [Data]
    var notes: String

    init(species: PlantSpecies, nickname: String = "", medium: PropagationMedium) {
        self.id = UUID()
        self.speciesID = species.id
        self.nickname = nickname.isEmpty ? species.commonName : nickname
        self.medium = medium
        self.cutDate = .now
        self.stage = .freshlyCut
        self.lastWaterChange = medium == .water ? .now : nil
        self.rootPhotoData = []
        self.notes = ""
    }

    var species: PlantSpecies? { PlantDatabase.species(id: speciesID) }

    var daysSinceCut: Int {
        Calendar.current.dateComponents([.day], from: cutDate, to: .now).day ?? 0
    }

    /// Rooted cuttings unlock marketplace listing.
    var canBeListed: Bool { stage == .rooted }

    var waterChangeOverdue: Bool {
        guard medium == .water, stage == .freshlyCut || stage == .rooting,
              let last = lastWaterChange else { return false }
        return Date.now.timeIntervalSince(last) > 3 * 24 * 3600
    }
}
