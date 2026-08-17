import Foundation
import SwiftData

/// Builds the app's SwiftData container.
///
/// One place defines the schema (all persisted `@Model` types) and hands back a
/// configured `ModelContainer`. If on-disk storage can't be opened, it falls back
/// to an in-memory store so the app still launches for a demo rather than
/// crashing on stage.
enum AppModelContainer {
    /// Every persisted model in the app.
    static let schema = Schema([
        Cutting.self,
        RootPhoto.self,
        SwapListing.self
    ])

    static func make(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            print("⚠️ AppModelContainer: on-disk store failed (\(error)); falling back to in-memory.")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            // If even an in-memory store can't be created, there's nothing to recover to.
            return try! ModelContainer(for: schema, configurations: fallback)
        }
    }
}
