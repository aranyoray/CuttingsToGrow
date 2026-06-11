import Foundation
import CoreLocation

/// Local-first store for swap listings, trade proposals, and drop zones.
/// Persists to disk now; designed so a backend sync layer can slot in behind
/// the same API later.
@MainActor
final class ExchangeStore: ObservableObject {
    @Published private(set) var listings: [SwapListing] = [] { didSet { persist() } }
    @Published private(set) var proposals: [TradeProposal] = [] { didSet { persist() } }

    let dropZones: [DropZone] = [
        DropZone(id: UUID(), name: "Corner Brew Café", detail: "Plant shelf by the window. Open 7am–6pm.",
                 latitude: 37.7793, longitude: -122.4193),
        DropZone(id: UUID(), name: "Public Library — Main Branch", detail: "Community swap table near the entrance.",
                 latitude: 37.7785, longitude: -122.4156),
        DropZone(id: UUID(), name: "Greenway Community Garden", detail: "Cuttings crate by the tool shed, weekends.",
                 latitude: 37.7720, longitude: -122.4230)
    ]

    private struct Snapshot: Codable {
        var listings: [SwapListing]
        var proposals: [TradeProposal]
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("exchange.json")
    }()

    init() {
        load()
        if listings.isEmpty { listings = Self.sampleListings }
    }

    func post(_ listing: SwapListing) {
        listings.append(listing)
    }

    func remove(_ listing: SwapListing) {
        listings.removeAll { $0.id == listing.id }
    }

    func propose(_ proposal: TradeProposal) {
        proposals.append(proposal)
    }

    func listings(matching kind: ListingKind?) -> [SwapListing] {
        guard let kind else { return listings }
        return listings.filter { $0.kind == kind }
    }

    private func persist() {
        let snapshot = Snapshot(listings: listings, proposals: proposals)
        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        listings = snapshot.listings
        proposals = snapshot.proposals
    }

    /// Demo listings so the Swap Map isn't empty on first launch.
    private static let sampleListings: [SwapListing] = [
        SwapListing(id: UUID(), cuttingID: UUID(), speciesID: "Epipremnum aureum",
                    title: "Rooted Golden Pothos — 3 nodes", kind: .freeToGoodHome,
                    handoff: .dropZone, wishlist: "",
                    latitude: 37.7775, longitude: -122.4163, postedDate: .now, ownerName: "Maya"),
        SwapListing(id: UUID(), cuttingID: UUID(), speciesID: "Capsicum annuum",
                    title: "Bell pepper seedlings (x4)", kind: .trade,
                    handoff: .meetup, wishlist: "Looking for any herb cuttings",
                    latitude: 37.7741, longitude: -122.4205, postedDate: .now, ownerName: "Devon"),
        SwapListing(id: UUID(), cuttingID: UUID(), speciesID: "Mentha spp.",
                    title: "Mint runners, very rooted", kind: .freeToGoodHome,
                    handoff: .dropZone, wishlist: "",
                    latitude: 37.7810, longitude: -122.4140, postedDate: .now, ownerName: "Sam")
    ]
}
