import SwiftUI
import PhotosUI

/// The Digital Nursery: every cutting's rooting journey, with water-change
/// nudges and photo-tracked progress that unlocks swap listing.
struct NurseryView: View {
    @EnvironmentObject private var nursery: NurseryStore

    var body: some View {
        NavigationStack {
            Group {
                if nursery.cuttings.isEmpty {
                    ContentUnavailableView(
                        "No cuttings yet",
                        systemImage: "leaf.circle",
                        description: Text("Scan a plant and take your first cutting to start your nursery.")
                    )
                } else {
                    List {
                        ForEach(nursery.cuttings) { cutting in
                            NavigationLink(value: cutting.id) {
                                CuttingRow(cutting: cutting)
                            }
                        }
                        .onDelete { offsets in
                            offsets.map { nursery.cuttings[$0] }.forEach(nursery.remove)
                        }
                    }
                    .navigationDestination(for: UUID.self) { id in
                        if let cutting = nursery.cuttings.first(where: { $0.id == id }) {
                            CuttingDetailView(cutting: cutting)
                        }
                    }
                }
            }
            .navigationTitle("Digital Nursery")
        }
    }
}

struct CuttingRow: View {
    let cutting: Cutting

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: cutting.stage.systemImage)
                .font(.title3)
                .foregroundStyle(Theme.leaf)
                .frame(width: 36, height: 36)
                .background(Theme.sprout.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(cutting.nickname).font(.headline)
                Text("\(cutting.stage.rawValue) · Day \(cutting.daysSinceCut) · \(cutting.medium.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if cutting.waterChangeOverdue {
                Image(systemName: "drop.triangle.fill")
                    .foregroundStyle(Theme.water)
                    .accessibilityLabel("Water change overdue")
            }
            if cutting.canBeListed {
                Image(systemName: "tag.fill")
                    .foregroundStyle(Theme.terracotta)
                    .accessibilityLabel("Ready to list for swap")
            }
        }
        .padding(.vertical, 2)
    }
}

struct CuttingDetailView: View {
    let cutting: Cutting
    @EnvironmentObject private var nursery: NurseryStore
    @EnvironmentObject private var exchange: ExchangeStore
    @State private var photoItem: PhotosPickerItem?
    @State private var showListSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let species = cutting.species {
                    HStack {
                        TagPill(text: species.difficulty.rawValue, icon: "chart.bar", color: Theme.leaf)
                        if species.toxicity.isToxicToAny {
                            TagPill(text: "Pet Toxic", icon: "pawprint.fill", color: Theme.warning)
                        }
                    }
                    progressCard(species)
                }

                if cutting.medium == .water, cutting.stage == .freshlyCut || cutting.stage == .rooting {
                    SectionCard(title: "Water Care", icon: "drop.fill") {
                        if let last = cutting.lastWaterChange {
                            Text("Last changed \(last.formatted(.relative(presentation: .named)))")
                                .font(.subheadline)
                        }
                        Button("Mark water changed") {
                            nursery.markWaterChanged(cutting)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                SectionCard(title: "Root Progress", icon: "camera") {
                    if cutting.rootPhotoData.isEmpty {
                        Text("Add a photo when you spot roots — that's what unlocks swap listings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(cutting.rootPhotoData.enumerated()), id: \.offset) { _, data in
                                    if let image = UIImage(data: data) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Add root photo", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                }

                if cutting.canBeListed {
                    Button {
                        showListSheet = true
                    } label: {
                        Label("List on the Swap Map", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else if cutting.stage == .rooting || cutting.stage == .freshlyCut {
                    Label("Swap listing unlocks once this cutting is rooted", systemImage: "lock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(cutting.nickname)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem) {
            guard let photoItem else { return }
            Task {
                if let data = try? await photoItem.loadTransferable(type: Data.self) {
                    promptRooted(with: data)
                }
                self.photoItem = nil
            }
        }
        .sheet(isPresented: $showListSheet) {
            NewListingView(cutting: cutting)
        }
        .confirmationDialog("Does this cutting have roots?",
                            isPresented: $askRooted, titleVisibility: .visible) {
            Button("Yes — fully rooted!") {
                if let data = pendingPhoto { nursery.logRootPhoto(data, for: cutting, nowRooted: true) }
                pendingPhoto = nil
            }
            Button("Not yet, still rooting") {
                if let data = pendingPhoto { nursery.logRootPhoto(data, for: cutting, nowRooted: false) }
                pendingPhoto = nil
            }
        }
    }

    @State private var askRooted = false
    @State private var pendingPhoto: Data?

    private func promptRooted(with data: Data) {
        pendingPhoto = data
        askRooted = true
    }

    private func progressCard(_ species: PlantSpecies) -> some View {
        let expected = cutting.medium == .water
            ? (species.waterRootDays ?? species.soilRootDays)
            : species.soilRootDays
        let progress = min(Double(cutting.daysSinceCut) / Double(expected.upperBound), 1.0)

        return SectionCard(title: "Rooting Timeline", icon: "clock") {
            ProgressView(value: cutting.stage == .rooted ? 1.0 : progress)
                .tint(Theme.leaf)
            Text(cutting.stage == .rooted
                 ? "Rooted in \(cutting.daysSinceCut) days 🎉"
                 : "Day \(cutting.daysSinceCut) of an expected \(expected.lowerBound)–\(expected.upperBound)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
