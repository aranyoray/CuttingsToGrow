import SwiftUI
import SwiftData

/// The local Swap Map.
///
/// Phase 0 shows the seeded demo listings as a simple, read-only list — enough to
/// prove the bundled data loaded and to carry the pet-safety thread through to
/// listings. The interactive MapKit map, filters, gift/trade flow, and the
/// "rooted unlocks listing" mechanic are built in Phase 4.
struct SwapMapView: View {
    @Query(sort: \SwapListing.createdDate, order: .reverse) private var listings: [SwapListing]

    var body: some View {
        NavigationStack {
            Group {
                if listings.isEmpty {
                    ContentUnavailableView(
                        "No listings yet",
                        systemImage: "map",
                        description: Text("Seeded demo listings will appear here on first launch.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(listings) { listing in
                                SwapListingRow(listing: listing)
                            }
                        } header: {
                            Text(listings.count == 1 ? "1 nearby listing" : "\(listings.count) nearby listings")
                        } footer: {
                            Text("The interactive Swap Map — with filters, gift/trade proposals, and public drop-off spots — arrives in a later phase. These are seeded demo listings; there's no server, everything is local.")
                        }
                    }
                }
            }
            .navigationTitle("Swap")
        }
    }
}

/// One listing row. Carries the flagship pet-safety badge so adopters see
/// toxicity before bringing a plant home.
struct SwapListingRow: View {
    let listing: SwapListing

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(listing.title).font(.headline)

            HStack(spacing: 8) {
                TagPill(text: listing.type.displayName,
                        systemImage: listing.type.systemImage,
                        color: listing.type == .gift ? Theme.sprout : Theme.terracotta)
                if let toxicity = listing.species?.toxicityOrUnknown {
                    ToxicityBadge(toxicity: toxicity)
                }
            }

            HStack(spacing: 4) {
                Text(listing.contactHandle)
                if !listing.wantedInReturn.isEmpty {
                    Text("· wants: \(listing.wantedInReturn)")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SwapMapView()
        .modelContainer(PreviewData.container)
}
