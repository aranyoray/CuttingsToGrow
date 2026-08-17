import Foundation
import SwiftData

/// Seeds demo Swap Map listings from `seed_listings.json` the first time the app
/// runs, so the Swap tab isn't empty in a demo.
///
/// Idempotent: it only inserts when the store has no listings yet, so it's safe to
/// call on every launch. There is no server — these are local records.
enum SeedService {
    /// Matches the top-level shape of `seed_listings.json`.
    private struct SeedFile: Decodable {
        let listings: [Listing]

        struct Listing: Decodable {
            let speciesID: String
            let title: String
            let type: ListingType
            let wantedInReturn: String
            let latitude: Double
            let longitude: Double
            let contactHandle: String
            let isActive: Bool
        }
    }

    static func seedIfNeeded(_ context: ModelContext) {
        let existingCount = (try? context.fetchCount(FetchDescriptor<SwapListing>())) ?? 0
        guard existingCount == 0 else { return }

        do {
            let file = try BundleLoader.decode(SeedFile.self, from: "seed_listings")
            for seed in file.listings {
                context.insert(SwapListing(
                    speciesID: seed.speciesID,
                    title: seed.title,
                    type: seed.type,
                    wantedInReturn: seed.wantedInReturn,
                    latitude: seed.latitude,
                    longitude: seed.longitude,
                    contactHandle: seed.contactHandle,
                    isActive: seed.isActive
                ))
            }
            try context.save()
        } catch {
            print("⚠️ SeedService failed: \(error)")
        }
    }
}
