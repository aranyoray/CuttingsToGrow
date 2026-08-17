import SwiftUI
import SwiftData
import PhotosUI
import UIKit // for UIImage(data:)

/// Everything about one cutting: its species guidance and pet-safety, a rooting
/// timeline, water care, a photo-tracked root-progress timeline, and edit/delete.
///
/// Adding a root photo asks "does it have roots yet?" — answering yes flips the
/// status to `rooted`, cancels its reminders, and (in Phase 4) unlocks listing.
struct CuttingDetailView: View {
    @Bindable var cutting: Cutting
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var pendingPhotoData: Data?
    @State private var askRooted = false
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var species: PlantSpecies? { cutting.species }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerTags
                rootingTimelineCard
                if cutting.medium == .water && cutting.status == .rooting {
                    waterCareCard
                }
                statusCard
                if let species { cutGuidanceCard(species) }
                if let toxicity = species?.toxicityOrUnknown, toxicity.isToxicToAnyPet || toxicity.verify {
                    petSafetyCard(toxicity)
                }
                rootPhotosCard
                if !cutting.notes.isEmpty { notesCard }
                deleteButton
            }
            .padding()
        }
        .background(Theme.groupedBackground)
        .navigationTitle(cutting.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditCuttingView(cutting: cutting)
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            // @MainActor because the closure mutates @State after the await.
            Task { @MainActor in
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    pendingPhotoData = data
                    askRooted = true
                }
                photoItem = nil
            }
        }
        .confirmationDialog("Does this cutting have roots yet?",
                            isPresented: $askRooted, titleVisibility: .visible) {
            Button("Yes — it's rooted! 🌱") { commitPhoto(markingRooted: true) }
            Button("Not yet, still rooting") { commitPhoto(markingRooted: false) }
            Button("Cancel", role: .cancel) { pendingPhotoData = nil }
        }
        .confirmationDialog("Delete this cutting?",
                            isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteCutting() }
        } message: {
            Text("This removes \(cutting.displayName) and its photos, and cancels its reminders.")
        }
    }

    // MARK: Cards

    private var headerTags: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let species {
                Text(species.commonName).font(.title3.weight(.semibold))
                Text(species.scientificName).font(.subheadline.italic()).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                if let species {
                    TagPill(text: species.difficulty.displayName,
                            systemImage: "chart.bar.fill",
                            color: Theme.color(for: species.difficulty))
                }
                TagPill(text: cutting.medium.displayName,
                        systemImage: cutting.medium.systemImage,
                        color: Theme.water)
                if let toxicity = species?.toxicityOrUnknown {
                    ToxicityBadge(toxicity: toxicity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rootingTimelineCard: some View {
        let expected = species?.rootTimeDays(in: cutting.medium)
        let progress: Double = {
            guard cutting.status != .rooted else { return 1 }
            guard let expected, expected > 0 else { return 0 }
            return min(Double(cutting.daysSinceStarted) / Double(expected), 1)
        }()

        return SectionCard(title: "Rooting timeline", systemImage: "clock") {
            ProgressView(value: progress).tint(Theme.leaf)
            if cutting.status == .rooted {
                Text("Rooted after \(cutting.daysSinceStarted) days 🎉")
                    .font(.caption).foregroundStyle(.secondary)
            } else if let expected {
                Text("Day \(cutting.daysSinceStarted) of about \(expected)")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Day \(cutting.daysSinceStarted)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var waterCareCard: some View {
        SectionCard(title: "Water care", systemImage: "drop.fill") {
            if cutting.waterChangeOverdue {
                Label("Water change overdue — swap in fresh water to prevent rot.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundStyle(Theme.terracotta)
            } else if let last = cutting.lastWaterChange {
                Text("Last changed \(last.formatted(.relative(presentation: .named)))")
                    .font(.subheadline)
            }
            Button {
                markWaterChanged()
            } label: {
                Label("Mark water changed", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.bordered)
        }
    }

    private var statusCard: some View {
        SectionCard(title: "Status", systemImage: cutting.status.systemImage) {
            Text(cutting.status.displayName).font(.headline).foregroundStyle(Theme.leaf)
            switch cutting.status {
            case .rooting:
                Text("Add a root photo below when you spot roots — that's what marks it rooted.")
                    .font(.caption).foregroundStyle(.secondary)
                Button {
                    markRooted()
                } label: {
                    Label("Mark as rooted", systemImage: "leaf.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            case .rooted:
                Label("Rooted! Listing on the Swap Map unlocks in a later phase.",
                      systemImage: "lock.open.fill")
                    .font(.caption).foregroundStyle(.secondary)
            case .listed:
                Text("Listed on the Swap Map.").font(.caption).foregroundStyle(.secondary)
            case .swapped:
                Text("Swapped — off to a new home. 🌿").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func cutGuidanceCard(_ species: PlantSpecies) -> some View {
        SectionCard(title: "Where to cut", systemImage: "scissors") {
            Text(species.cutLocationDescription).font(.subheadline)
            if species.needsRootingHormone {
                Label("Rooting hormone recommended", systemImage: "flask.fill")
                    .font(.caption).foregroundStyle(Theme.terracotta)
            }
            if !species.notes.isEmpty {
                Text(species.notes).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func petSafetyCard(_ toxicity: ToxicityInfo) -> some View {
        SectionCard(title: "Pet safety", systemImage: "pawprint.fill") {
            ToxicityBadge(toxicity: toxicity)
            Text(toxicity.severityNote).font(.subheadline)
            if toxicity.verify {
                Label("This toxicity note is flagged to verify before you rely on it.",
                      systemImage: "exclamationmark.circle")
                    .font(.caption).foregroundStyle(Theme.caution)
            }
            Text("Source: \(toxicity.source)").font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private var rootPhotosCard: some View {
        SectionCard(title: "Root progress", systemImage: "camera.fill") {
            let photos = cutting.rootPhotos.sorted { $0.date < $1.date }
            if photos.isEmpty {
                Text("No photos yet. Add one when you see roots — you'll be asked if it's rooted.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(photos) { photo in
                            VStack(spacing: 4) {
                                photoThumbnail(photo)
                                Text(photo.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundStyle(.secondary)
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
    }

    private var notesCard: some View {
        SectionCard(title: "Your notes", systemImage: "note.text") {
            Text(cutting.notes).font(.subheadline)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete cutting", systemImage: "trash").frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Theme.warning)
    }

    @ViewBuilder
    private func photoThumbnail(_ photo: RootPhoto) -> some View {
        if let image = UIImage(data: photo.imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.sprout.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
        }
    }

    // MARK: Actions

    private func markWaterChanged() {
        cutting.lastWaterChange = .now
        try? context.save()
        NotificationService.shared.scheduleWaterReminder(for: cutting) // resets the 3-day clock
    }

    private func markRooted() {
        cutting.status = .rooted
        try? context.save()
        NotificationService.shared.cancelReminders(for: cutting)
    }

    private func commitPhoto(markingRooted: Bool) {
        guard let data = pendingPhotoData else { return }
        let photo = RootPhoto(imageData: data)
        context.insert(photo)
        photo.cutting = cutting // SwiftData maintains the inverse (cutting.rootPhotos)
        if markingRooted {
            cutting.status = .rooted
            NotificationService.shared.cancelReminders(for: cutting)
        }
        try? context.save()
        pendingPhotoData = nil
    }

    private func deleteCutting() {
        NotificationService.shared.cancelReminders(for: cutting)
        // Dismiss first, then delete on the next runloop tick so this view stops
        // observing the model before it's removed (avoids a deleted-object crash).
        dismiss()
        DispatchQueue.main.async {
            context.delete(cutting)
            try? context.save()
        }
    }
}

#Preview {
    NavigationStack {
        if let cutting = try? PreviewData.container.mainContext.fetch(FetchDescriptor<Cutting>()).first {
            CuttingDetailView(cutting: cutting)
        } else {
            Text("No preview cutting")
        }
    }
    .modelContainer(PreviewData.container)
}
