import Foundation
import SwiftUI

/// Local persistence for the Digital Nursery, with water-change reminders.
@MainActor
final class NurseryStore: ObservableObject {
    @Published private(set) var cuttings: [Cutting] = [] {
        didSet { persist() }
    }

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("nursery.json")
    }()

    init() {
        load()
    }

    func add(_ cutting: Cutting) {
        cuttings.append(cutting)
        if cutting.medium == .water {
            NotificationService.shared.scheduleWaterChangeReminder(for: cutting)
        }
        if let species = cutting.species {
            NotificationService.shared.scheduleRootCheckReminder(for: cutting, species: species)
        }
    }

    func update(_ cutting: Cutting) {
        guard let idx = cuttings.firstIndex(where: { $0.id == cutting.id }) else { return }
        cuttings[idx] = cutting
    }

    func remove(_ cutting: Cutting) {
        cuttings.removeAll { $0.id == cutting.id }
        NotificationService.shared.cancelReminders(for: cutting)
    }

    func markWaterChanged(_ cutting: Cutting) {
        var updated = cutting
        updated.lastWaterChange = .now
        update(updated)
        NotificationService.shared.scheduleWaterChangeReminder(for: updated)
    }

    /// A root-progress photo update; rooted cuttings unlock the swap marketplace.
    func logRootPhoto(_ data: Data, for cutting: Cutting, nowRooted: Bool) {
        var updated = cutting
        updated.rootPhotoData.append(data)
        if nowRooted {
            updated.stage = .rooted
            NotificationService.shared.cancelReminders(for: updated)
        } else if updated.stage == .freshlyCut {
            updated.stage = .rooting
        }
        update(updated)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(cuttings) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? JSONDecoder().decode([Cutting].self, from: data) else { return }
        cuttings = saved
    }
}
