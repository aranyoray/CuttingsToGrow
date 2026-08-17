import SwiftUI
import SwiftData

/// The Digital Nursery — the heart of the app.
///
/// A complete, competition-eligible feature on its own: add cuttings, track each
/// one's status and rooting timeline, get water-change reminders, and log a
/// photo timeline of roots forming. Rooted cuttings later unlock the Swap Map.
struct NurseryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Cutting.dateStarted, order: .reverse) private var cuttings: [Cutting]

    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if cuttings.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(cuttings) { cutting in
                            NavigationLink {
                                CuttingDetailView(cutting: cutting)
                            } label: {
                                CuttingRow(cutting: cutting)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Nursery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add cutting", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddCuttingView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your nursery is empty", systemImage: "leaf.circle")
        } description: {
            Text("Take your first cutting to start tracking it — with water-change reminders and a photo timeline that follows the roots. Once a cutting has roots, you can gift or trade it on the Swap Map.")
        } actions: {
            Button {
                showAdd = true
            } label: {
                Label("Add a cutting", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let cutting = cuttings[index]
            NotificationService.shared.cancelReminders(for: cutting)
            context.delete(cutting)
        }
        try? context.save()
    }
}

/// A single row in the nursery list.
struct CuttingRow: View {
    let cutting: Cutting

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: cutting.status.systemImage)
                .font(.title3)
                .foregroundStyle(Theme.leaf)
                .frame(width: 36, height: 36)
                .background(Theme.sprout.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(cutting.displayName).font(.headline)
                Text("\(cutting.status.displayName) · Day \(cutting.daysSinceStarted) · \(cutting.medium.displayName)")
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

#Preview("Empty") {
    NurseryView()
        .modelContainer(AppModelContainer.make(inMemory: true))
}

#Preview("With cuttings") {
    NurseryView()
        .modelContainer(PreviewData.container)
}
