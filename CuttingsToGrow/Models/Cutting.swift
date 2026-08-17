import Foundation
import SwiftData

/// Where a cutting is in its journey. Rooted cuttings unlock swap listing.
enum CuttingStatus: String, Codable, CaseIterable {
    case rooting
    case rooted
    case listed
    case swapped

    var displayName: String {
        switch self {
        case .rooting: return "Rooting"
        case .rooted: return "Rooted"
        case .listed: return "Listed for Swap"
        case .swapped: return "Swapped"
        }
    }

    var systemImage: String {
        switch self {
        case .rooting: return "drop.fill"
        case .rooted: return "leaf.fill"
        case .listed: return "tag.fill"
        case .swapped: return "hands.and.sparkles.fill"
        }
    }
}

/// A cutting the user is rooting in their Digital Nursery.
///
/// This is a SwiftData `@Model` — user-generated, mutable, and persisted locally.
/// It links to reference data (`PlantSpecies`) by `speciesID` (the species'
/// scientific name), because the species catalog ships in JSON rather than the
/// user's store.
@Model
final class Cutting {
    /// Stable identity for `Identifiable`/`ForEach`. SwiftData also keeps its own
    /// `persistentModelID` for storage; this UUID is the app-facing id and the
    /// link target for `SwapListing.cuttingID`.
    var id: UUID
    /// Links to `PlantSpecies.id` (scientific name) in the knowledge base.
    var speciesID: String
    var nickname: String
    var medium: PropagationMedium
    var status: CuttingStatus
    var dateStarted: Date
    /// Last time the water was refreshed (drives the 3-day reminder in Phase 1).
    var lastWaterChange: Date?
    var notes: String

    /// Photo timeline. Deleting a cutting deletes its photos (cascade).
    @Relationship(deleteRule: .cascade, inverse: \RootPhoto.cutting)
    var rootPhotos: [RootPhoto]

    init(
        id: UUID = UUID(),
        speciesID: String,
        nickname: String,
        medium: PropagationMedium,
        status: CuttingStatus = .rooting,
        dateStarted: Date = .now,
        lastWaterChange: Date? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.speciesID = speciesID
        self.nickname = nickname
        self.medium = medium
        self.status = status
        self.dateStarted = dateStarted
        self.lastWaterChange = lastWaterChange
        self.notes = notes
        self.rootPhotos = []
    }
}

// MARK: - Convenience (computed, not persisted)

extension Cutting {
    /// Looks the species up in the bundled catalog. Optional because the store
    /// could, in theory, hold an id that isn't in the current catalog.
    var species: PlantSpecies? {
        KnowledgeBaseService.shared.species(id: speciesID)
    }

    var displayName: String {
        nickname.isEmpty ? (species?.commonName ?? "Cutting") : nickname
    }

    var daysSinceStarted: Int {
        Calendar.current.dateComponents([.day], from: dateStarted, to: .now).day ?? 0
    }

    /// Only rooted cuttings can be listed on the Swap Map (the "unlock" mechanic).
    var canBeListed: Bool { status == .rooted }

    /// True when a water-propagated cutting hasn't had its water changed in 3+ days.
    var waterChangeOverdue: Bool {
        guard medium == .water,
              status == .rooting,
              let last = lastWaterChange else { return false }
        return Date.now.timeIntervalSince(last) > 3 * 24 * 3600
    }
}
