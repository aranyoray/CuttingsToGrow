import SwiftUI
import SwiftData

/// The three-tab shell: Scan, Nursery, Swap.
///
/// The Digital Nursery (Phase 1) is the heart of the app and the first tab to
/// become fully functional; Scan (Phases 2–3) and the Swap Map (Phase 4) fill in
/// after. On first appearance we seed demo Swap listings so nothing looks empty.
struct RootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            ScanView()
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }

            NurseryView()
                .tabItem { Label("Nursery", systemImage: "leaf.fill") }

            SwapMapView()
                .tabItem { Label("Swap", systemImage: "map.fill") }
        }
        .task {
            // Idempotent: only seeds when the store has no listings yet.
            SeedService.seedIfNeeded(context)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewData.container)
}
