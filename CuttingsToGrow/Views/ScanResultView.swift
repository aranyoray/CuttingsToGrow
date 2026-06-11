import SwiftUI

/// The Safety & Viability triage card shown after a successful scan.
struct ScanResultView: View {
    let result: ScanResult
    @EnvironmentObject private var nursery: NurseryStore
    @Environment(\.dismiss) private var dismiss
    @State private var addedToNursery = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if let species = result.species {
                    speciesDetail(species)
                } else {
                    unknownPlant
                }
            }
            .navigationTitle(result.species?.commonName ?? "Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func speciesDetail(_ species: PlantSpecies) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(species.scientificName)
                    .font(.subheadline.italic())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(result.confidence * 100))% match")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Triage tags — difficulty + toxicity, always visible first.
            HStack {
                TagPill(text: species.difficulty.rawValue,
                        icon: difficultyIcon(species.difficulty),
                        color: difficultyColor(species.difficulty))
                TagPill(text: species.preferredMedium.rawValue,
                        icon: species.preferredMedium == .water ? "drop.fill" : "square.stack.3d.up.fill",
                        color: Theme.water)
                if species.toxicity.isToxicToAny {
                    TagPill(text: "Pet Toxic", icon: "pawprint.fill", color: Theme.warning)
                } else {
                    TagPill(text: "Pet Safe", icon: "pawprint", color: Theme.sprout)
                }
            }

            if species.toxicity.isToxicToAny {
                SectionCard(title: "Pet Safety Warning", icon: "exclamationmark.triangle.fill") {
                    Text("Toxic if chewed by: \(species.toxicity.affectedPets.joined(separator: ", ")). Keep out of reach of roaming pets.")
                        .font(.subheadline)
                }
                .foregroundStyle(Theme.warning)
            }

            SectionCard(title: "Where to Cut", icon: "scissors") {
                Text(species.cuttingGuidance)
                    .font(.subheadline)
            }

            SectionCard(title: "Rooting Time", icon: "clock") {
                if let water = species.waterRootDays {
                    Label("Water: \(water.lowerBound)–\(water.upperBound) days", systemImage: "drop")
                        .font(.subheadline)
                } else {
                    Label("Water propagation not recommended (rot risk)", systemImage: "drop.triangle")
                        .font(.subheadline)
                        .foregroundStyle(Theme.terracotta)
                }
                Label("Soil: \(species.soilRootDays.lowerBound)–\(species.soilRootDays.upperBound) days",
                      systemImage: "square.stack.3d.up")
                    .font(.subheadline)
                Text(species.difficulty.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                let cutting = Cutting(species: species, medium: species.preferredMedium)
                nursery.add(cutting)
                addedToNursery = true
            } label: {
                Label(addedToNursery ? "Added to Nursery" : "I took a cutting — add to Nursery",
                      systemImage: addedToNursery ? "checkmark" : "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(addedToNursery)
        }
        .padding()
    }

    private var unknownPlant: some View {
        VStack(spacing: 14) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Couldn't match this plant")
                .font(.headline)
            Text("Best guess: \"\(result.rawLabel)\". Try filling the frame with leaves and a section of stem in good light.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .padding(.horizontal)
    }

    private func difficultyIcon(_ d: PropagationDifficulty) -> String {
        switch d {
        case .beginner: return "1.circle"
        case .intermediate: return "2.circle"
        case .advanced: return "3.circle"
        }
    }

    private func difficultyColor(_ d: PropagationDifficulty) -> Color {
        switch d {
        case .beginner: return Theme.sprout
        case .intermediate: return Theme.terracotta
        case .advanced: return Theme.warning
        }
    }
}
