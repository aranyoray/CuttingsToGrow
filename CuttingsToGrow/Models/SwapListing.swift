import Foundation
import CoreLocation

enum ListingKind: String, Codable, CaseIterable {
    case freeToGoodHome = "Free to a Good Home"
    case trade = "Open to Trade"
}

enum HandoffMethod: String, Codable, CaseIterable {
    case dropZone = "Public Drop-off Zone"
    case mailIn = "Mail-in (sphagnum-packed)"
    case meetup = "In-person Meetup"
}

struct SwapListing: Identifiable, Codable, Hashable {
    let id: UUID
    var cuttingID: UUID
    var speciesID: String
    var title: String
    var kind: ListingKind
    var handoff: HandoffMethod
    var wishlist: String
    var latitude: Double
    var longitude: Double
    var postedDate: Date
    var ownerName: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var species: PlantSpecies? { PlantDatabase.species(id: speciesID) }
}

struct TradeProposal: Identifiable, Codable, Hashable {
    let id: UUID
    var listingID: UUID
    var offeredCuttingID: UUID
    var message: String
    var date: Date
}

/// A partnered safe handoff location (cafe, library, community garden).
struct DropZone: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var detail: String
    var latitude: Double
    var longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
