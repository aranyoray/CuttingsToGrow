import CoreLocation
import Foundation
import SwiftData

/// Whether a listing is a giveaway or a swap.
enum ListingType: String, Codable, CaseIterable {
    case gift
    case trade

    var displayName: String {
        switch self {
        case .gift: return "Free to a Good Home"
        case .trade: return "Open to Trade"
        }
    }

    var systemImage: String {
        switch self {
        case .gift: return "gift.fill"
        case .trade: return "arrow.triangle.2.circlepath"
        }
    }
}

/// A listing on the local Swap Map.
///
/// A SwiftData `@Model`, stored locally. Listings come from two sources: the
/// bundled `seed_listings.json` (seeded once on first launch so the map isn't
/// empty) and, in Phase 4, the user's own rooted cuttings. There is no server —
/// this is local-first by design, documented as future work in `LEARN.md`.
@Model
final class SwapListing {
    var id: UUID
    /// The user's own cutting this listing came from; `nil` for seeded demo data.
    var cuttingID: UUID?
    /// Links to `PlantSpecies.id` (scientific name).
    var speciesID: String
    var title: String
    var type: ListingType
    var wantedInReturn: String
    var latitude: Double
    var longitude: Double
    var contactHandle: String
    var isActive: Bool
    var createdDate: Date

    init(
        id: UUID = UUID(),
        cuttingID: UUID? = nil,
        speciesID: String,
        title: String,
        type: ListingType,
        wantedInReturn: String = "",
        latitude: Double,
        longitude: Double,
        contactHandle: String,
        isActive: Bool = true,
        createdDate: Date = .now
    ) {
        self.id = id
        self.cuttingID = cuttingID
        self.speciesID = speciesID
        self.title = title
        self.type = type
        self.wantedInReturn = wantedInReturn
        self.latitude = latitude
        self.longitude = longitude
        self.contactHandle = contactHandle
        self.isActive = isActive
        self.createdDate = createdDate
    }
}

// MARK: - Convenience (computed, not persisted)

extension SwapListing {
    var species: PlantSpecies? {
        KnowledgeBaseService.shared.species(id: speciesID)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
