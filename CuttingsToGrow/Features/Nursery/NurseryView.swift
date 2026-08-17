import SwiftUI
import SwiftData

/// The Digital Nursery.
///
/// Phase 0 wires up the SwiftData `@Query` and a polished empty state. The full
/// feature — adding cuttings, water-change reminders, and the root-progress photo
/// timeline — lands in Phase 1, at which point this becomes a complete,
/// competition-eligible app on its own.
struct NurseryView: View {
    @Query(sort: \Cutting.dateStarted, order: .reverse) private var cuttings: [Cutting]

    var body: some View {
        NavigationStack {
            Group {
                if cuttings.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(cuttings) { cutting in
                            CuttingRow(cutting: cutting)
                        }
                    }
                }
            }
            .navigationTitle("Nursery")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Your nursery is empty", systemImage: "leaf.circle")
        } description: {
            Text("Cuttings you take will grow here — with water-change reminders and a photo timeline that tracks roots. Once a cutting has roots, you can gift or trade it on the Swap Map.\n\nAdding cuttings arrives in the next phase.")
        }
    }
}

/// A single row in the nursery list. Reused as the nursery fills out in Phase 1.
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
