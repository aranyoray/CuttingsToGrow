import SwiftUI
import CoreLocation

/// Browse listings as a feed, propose trades, and manage your own posts.
struct ExchangeView: View {
    @EnvironmentObject private var exchange: ExchangeStore
    @State private var filter: ListingKind?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Filter", selection: $filter) {
                        Text("All").tag(ListingKind?.none)
                        ForEach(ListingKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue).tag(ListingKind?.some(kind))
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                Section("Nearby Listings") {
                    ForEach(exchange.listings(matching: filter)) { listing in
                        NavigationLink {
                            ListingDetailView(listing: listing)
                        } label: {
                            ListingRow(listing: listing)
                        }
                    }
                }

                Section("Safe Handoff Spots") {
                    ForEach(exchange.dropZones) { zone in
                        Label {
                            VStack(alignment: .leading) {
                                Text(zone.name).font(.subheadline.weight(.medium))
                                Text(zone.detail).font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "shippingbox.fill")
                                .foregroundStyle(Theme.soil)
                        }
                    }
                }
            }
            .navigationTitle("Exchange")
        }
    }
}

struct ListingRow: View {
    let listing: SwapListing

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(listing.title).font(.headline)
            HStack {
                TagPill(text: listing.kind.rawValue,
                        icon: listing.kind == .freeToGoodHome ? "gift" : "arrow.triangle.2.circlepath",
                        color: listing.kind == .freeToGoodHome ? Theme.sprout : Theme.terracotta)
                if let species = listing.species, species.toxicity.isToxicToAny {
                    TagPill(text: "Pet Toxic", icon: "pawprint.fill", color: Theme.warning)
                }
            }
            Text("by \(listing.ownerName) · \(listing.handoff.rawValue)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct ListingDetailView: View {
    let listing: SwapListing
    @EnvironmentObject private var exchange: ExchangeStore
    @EnvironmentObject private var nursery: NurseryStore
    @Environment(\.dismiss) private var dismiss
    @State private var offeredCuttingID: UUID?
    @State private var message = ""
    @State private var sent = false

    private var tradableCuttings: [Cutting] {
        nursery.cuttings.filter(\.canBeListed)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(listing.title).font(.headline)
                    if let species = listing.species {
                        LabeledContent("Species", value: species.commonName)
                        LabeledContent("Difficulty", value: species.difficulty.rawValue)
                        if species.toxicity.isToxicToAny {
                            Label("Toxic to: \(species.toxicity.affectedPets.joined(separator: ", ")) — check before bringing home",
                                  systemImage: "pawprint.fill")
                                .font(.footnote)
                                .foregroundStyle(Theme.warning)
                        } else {
                            Label("Pet safe", systemImage: "pawprint")
                                .font(.footnote)
                                .foregroundStyle(Theme.sprout)
                        }
                    }
                    LabeledContent("Handoff", value: listing.handoff.rawValue)
                    if !listing.wishlist.isEmpty {
                        LabeledContent("Looking for", value: listing.wishlist)
                    }
                }

                if listing.kind == .trade {
                    Section("Propose a 1-for-1 Trade") {
                        if tradableCuttings.isEmpty {
                            Text("You need a rooted cutting in your Nursery to offer a trade.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Offer", selection: $offeredCuttingID) {
                                Text("Choose a cutting").tag(UUID?.none)
                                ForEach(tradableCuttings) { cutting in
                                    Text(cutting.nickname).tag(UUID?.some(cutting.id))
                                }
                            }
                            TextField("Message (optional)", text: $message, axis: .vertical)
                            Button(sent ? "Proposal sent!" : "Send trade proposal") {
                                guard let offeredCuttingID else { return }
                                exchange.propose(TradeProposal(
                                    id: UUID(), listingID: listing.id,
                                    offeredCuttingID: offeredCuttingID,
                                    message: message, date: .now
                                ))
                                sent = true
                            }
                            .disabled(offeredCuttingID == nil || sent)
                        }
                    }
                } else {
                    Section {
                        Button(sent ? "Request sent!" : "Request this cutting") {
                            sent = true
                        }
                        .disabled(sent)
                    }
                }

                if listing.handoff == .mailIn {
                    Section("Mailing Tips") {
                        Text("Wrap bare roots in damp sphagnum moss, then a loose plastic sleeve. Pad the box so the stem can't shift, and ship early in the week to avoid weekend warehouse delays.")
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }
}

/// Create a listing for a rooted cutting from the Nursery.
struct NewListingView: View {
    let cutting: Cutting
    @EnvironmentObject private var exchange: ExchangeStore
    @EnvironmentObject private var nursery: NurseryStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var kind: ListingKind = .freeToGoodHome
    @State private var handoff: HandoffMethod = .dropZone
    @State private var wishlist = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Listing") {
                    TextField("Title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(ListingKind.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    if kind == .trade {
                        TextField("What are you looking for?", text: $wishlist)
                    }
                }
                Section("Handoff") {
                    Picker("Method", selection: $handoff) {
                        ForEach(HandoffMethod.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    if handoff == .dropZone {
                        Text("Pick a partnered café, library, or community garden from the Swap Map after posting.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if let species = cutting.species, species.toxicity.isToxicToAny {
                    Section {
                        Label("This species is pet-toxic — the listing will carry a warning badge automatically.",
                              systemImage: "pawprint.fill")
                            .font(.footnote)
                            .foregroundStyle(Theme.warning)
                    }
                }
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { post() }
                        .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if title.isEmpty {
                    title = "Rooted \(cutting.nickname)"
                }
            }
        }
    }

    private func post() {
        exchange.post(SwapListing(
            id: UUID(),
            cuttingID: cutting.id,
            speciesID: cutting.speciesID,
            title: title,
            kind: kind,
            handoff: handoff,
            wishlist: wishlist,
            latitude: 37.7770, longitude: -122.4190, // replaced by user location when available
            postedDate: .now,
            ownerName: "You"
        ))
        var updated = cutting
        updated.stage = .listed
        nursery.update(updated)
        dismiss()
    }
}
