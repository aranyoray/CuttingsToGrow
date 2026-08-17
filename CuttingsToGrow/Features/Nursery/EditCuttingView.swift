import SwiftUI
import SwiftData

/// Edit a cutting's nickname, rooting medium, status, and notes.
///
/// It edits **local copies** and applies them on Save, so Cancel genuinely
/// discards changes. On Save it also re-syncs reminders: changing to/from water
/// or marking the cutting rooted schedules or cancels the right notifications.
struct EditCuttingView: View {
    let cutting: Cutting
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String
    @State private var medium: PropagationMedium
    @State private var status: CuttingStatus
    @State private var notes: String

    init(cutting: Cutting) {
        self.cutting = cutting
        _nickname = State(initialValue: cutting.nickname)
        _medium = State(initialValue: cutting.medium)
        _status = State(initialValue: cutting.status)
        _notes = State(initialValue: cutting.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Nickname", text: $nickname)
                    Picker("Rooting in", selection: $medium) {
                        ForEach(PropagationMedium.allCases, id: \.self) { medium in
                            Label(medium.displayName, systemImage: medium.systemImage).tag(medium)
                        }
                    }
                    Picker("Status", selection: $status) {
                        ForEach(CuttingStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(1...5)
                }
            }
            .navigationTitle("Edit Cutting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
        }
    }

    private func save() {
        let wasRooted = cutting.status == .rooted

        cutting.nickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        cutting.medium = medium
        cutting.status = status
        cutting.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if medium == .water && cutting.lastWaterChange == nil {
            cutting.lastWaterChange = .now
        }
        try? context.save()

        // Re-sync reminders to the new state.
        let notifier = NotificationService.shared
        if status == .rooted || status == .listed || status == .swapped {
            notifier.cancelReminders(for: cutting)
        } else {
            // Still rooting: (re)schedule per the (possibly new) medium.
            notifier.cancelWaterReminder(for: cutting)
            notifier.scheduleWaterReminder(for: cutting)
            if wasRooted, let species = cutting.species {
                // Reverted rooted -> rooting: restore the root-check nudge too.
                notifier.scheduleRootCheckReminder(for: cutting, species: species)
            }
        }

        dismiss()
    }
}

#Preview {
    if let cutting = try? PreviewData.container.mainContext.fetch(FetchDescriptor<Cutting>()).first {
        EditCuttingView(cutting: cutting)
            .modelContainer(PreviewData.container)
    } else {
        Text("No preview cutting")
    }
}
