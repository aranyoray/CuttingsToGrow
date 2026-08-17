import SwiftUI
import SwiftData

/// Start a new cutting: pick a species, name it, choose the rooting medium, and
/// (optionally) add a note. On save it's inserted into the store and its
/// water-change + root-check reminders are scheduled.
struct AddCuttingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSpecies: PlantSpecies?
    @State private var nickname = ""
    @State private var medium: PropagationMedium = .water
    @State private var notes = ""
    @State private var showSpeciesPicker = false

    var body: some View {
        NavigationStack {
            Form {
                speciesSection
                if let species = selectedSpecies {
                    detailsSection(for: species)
                    guidancePreview(for: species)
                }
            }
            .navigationTitle("New Cutting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selectedSpecies == nil)
                }
            }
            .sheet(isPresented: $showSpeciesPicker) {
                SpeciesPickerView(selection: $selectedSpecies)
            }
            .onChange(of: selectedSpecies) { _, species in
                // Default the medium to whatever the species prefers.
                if let species { medium = species.preferredMedium }
            }
        }
    }

    // MARK: Sections

    private var speciesSection: some View {
        Section("Plant") {
            Button {
                showSpeciesPicker = true
            } label: {
                HStack {
                    Text("Species").foregroundStyle(.primary)
                    Spacer()
                    Text(selectedSpecies?.commonName ?? "Choose")
                        .foregroundStyle(selectedSpecies == nil ? .secondary : Theme.leaf)
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
            }
            if let species = selectedSpecies {
                HStack(spacing: 8) {
                    TagPill(text: species.difficulty.displayName,
                            systemImage: "chart.bar.fill",
                            color: Theme.color(for: species.difficulty))
                    ToxicityBadge(toxicity: species.toxicityOrUnknown)
                }
            }
        }
    }

    private func detailsSection(for species: PlantSpecies) -> some View {
        Section("Details") {
            TextField("Nickname (optional)", text: $nickname)
            Picker("Rooting in", selection: $medium) {
                ForEach(PropagationMedium.allCases, id: \.self) { medium in
                    Label(medium.displayName, systemImage: medium.systemImage).tag(medium)
                }
            }
            if medium == .water && species.rootTimeWaterDays == nil {
                Label("Water propagation isn't recommended for this plant — it tends to rot. Consider soil.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.terracotta)
            }
            TextField("Notes (optional)", text: $notes, axis: .vertical)
                .lineLimit(1...4)
        }
    }

    private func guidancePreview(for species: PlantSpecies) -> some View {
        Section("Where to cut") {
            Text(species.cutLocationDescription)
                .font(.subheadline)
            Label(species.rootTimeSummary, systemImage: "clock")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: Save

    private func save() {
        guard let species = selectedSpecies else { return }
        let cutting = Cutting(
            speciesID: species.id,
            nickname: nickname.trimmingCharacters(in: .whitespacesAndNewlines),
            medium: medium,
            status: .rooting,
            lastWaterChange: medium == .water ? .now : nil,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(cutting)
        try? context.save()

        // Reminders are opt-in via the system prompt; ask now that there's a
        // concrete reason ("we'll remind you to change the water").
        NotificationService.shared.requestAuthorization()
        NotificationService.shared.scheduleReminders(for: cutting, species: species)

        dismiss()
    }
}

#Preview {
    AddCuttingView()
        .modelContainer(PreviewData.container)
}
