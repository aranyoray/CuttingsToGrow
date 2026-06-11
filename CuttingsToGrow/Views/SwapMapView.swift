import SwiftUI
import MapKit

/// The local Swap Map: nearby listings plus partnered drop-off zones.
struct SwapMapView: View {
    @EnvironmentObject private var exchange: ExchangeStore
    @State private var filter: ListingKind?
    @State private var selectedListing: SwapListing?

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7770, longitude: -122.4190),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
    )

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                UserAnnotation()

                ForEach(exchange.listings(matching: filter)) { listing in
                    Annotation(listing.species?.commonName ?? listing.title,
                               coordinate: listing.coordinate) {
                        Button { selectedListing = listing } label: {
                            Image(systemName: "leaf.fill")
                                .font(.callout)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(listing.kind == .freeToGoodHome ? Theme.sprout : Theme.terracotta,
                                            in: Circle())
                                .shadow(radius: 2)
                        }
                    }
                }

                ForEach(exchange.dropZones) { zone in
                    Annotation(zone.name, coordinate: zone.coordinate) {
                        Image(systemName: "shippingbox.fill")
                            .font(.callout)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Theme.soil, in: Circle())
                            .shadow(radius: 2)
                    }
                }
            }
            .mapControls { MapUserLocationButton() }
            .navigationTitle("Swap Map")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top) { filterBar }
            .sheet(item: $selectedListing) { listing in
                ListingDetailView(listing: listing)
                    .presentationDetents([.medium])
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                filterChip("All", value: nil)
                filterChip("Free to a Good Home", value: .freeToGoodHome)
                filterChip("Open to Trade", value: .trade)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func filterChip(_ label: String, value: ListingKind?) -> some View {
        Button {
            withAnimation { filter = value }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(filter == value ? Theme.leaf : Color(.tertiarySystemFill),
                            in: Capsule())
                .foregroundStyle(filter == value ? .white : .primary)
        }
    }
}
