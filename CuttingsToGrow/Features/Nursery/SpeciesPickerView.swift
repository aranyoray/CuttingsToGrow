import SwiftUI

/// A searchable, category-grouped list of every species in the knowledge base.
/// Used when starting a new cutting. Selecting one dismisses and returns it.
struct SpeciesPickerView: View {
    @Binding var selection: PlantSpecies?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private let grouped = KnowledgeBaseService.shared.speciesByCategory()

    private var filteredGroups: [(category: PlantCategory, species: [PlantSpecies])] {
        guard !query.isEmpty else { return grouped }
        let q = query.lowercased()
        return grouped.compactMap { group in
            let matches = group.species.filter {
                $0.commonName.lowercased().contains(q) || $0.scientificName.lowercased().contains(q)
            }
            return matches.isEmpty ? nil : (group.category, matches)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredGroups, id: \.category) { group in
                    Section(group.category.displayName) {
                        ForEach(group.species) { species in
                            Button {
                                selection = species
                                dismiss()
                            } label: {
                                SpeciesRow(species: species)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search plants")
            .overlay {
                if filteredGroups.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .navigationTitle("Choose a Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

/// One species row: name, scientific name, difficulty, and the pet-safety badge.
struct SpeciesRow: View {
    let species: PlantSpecies

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(species.commonName).font(.headline).foregroundStyle(.primary)
            Text(species.scientificName).font(.caption.italic()).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                TagPill(text: species.difficulty.displayName,
                        systemImage: "chart.bar.fill",
                        color: Theme.color(for: species.difficulty))
                ToxicityBadge(toxicity: species.toxicityOrUnknown)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SpeciesPickerView(selection: .constant(nil))
}
