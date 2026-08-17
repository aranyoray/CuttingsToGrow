import SwiftUI
import SwiftData

/// App entry point.
///
/// It builds the SwiftData container once and injects it into the view hierarchy.
/// First-launch seeding of demo Swap listings happens in `RootView.task`, which
/// runs on the main actor with the environment's model context — the idiomatic,
/// concurrency-safe place to touch the store.
@main
struct CuttingsGardenApp: App {
    /// The shared persistent store for the whole app.
    let container = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Theme.leaf)
        }
        .modelContainer(container)
    }
}
