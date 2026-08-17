import Foundation
import SwiftData

/// In-memory sample data for SwiftUI previews.
///
/// Previews should never touch the real on-disk store, so this builds a throwaway
/// in-memory container, drops in a couple of representative cuttings, and seeds
/// the demo listings. Feature views use `PreviewData.container` in their
/// `#Preview` blocks.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let container = AppModelContainer.make(inMemory: true)
        let context = container.mainContext

        // A water cutting mid-root...
        if let pothos = KnowledgeBaseService.shared.species(id: "Epipremnum aureum") {
            context.insert(Cutting(
                speciesID: pothos.id,
                nickname: "Kitchen pothos",
                medium: .water,
                status: .rooting,
                dateStarted: Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now,
                lastWaterChange: .now
            ))
        }
        // ...and a rooted one, ready to list.
        if let basil = KnowledgeBaseService.shared.species(id: "Ocimum basilicum") {
            context.insert(Cutting(
                speciesID: basil.id,
                nickname: "Windowsill basil",
                medium: .water,
                status: .rooted,
                dateStarted: Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now
            ))
        }

        SeedService.seedIfNeeded(context)
        return container
    }()

    /// A representative species for detail-view previews.
    static var sampleSpecies: PlantSpecies {
        KnowledgeBaseService.shared.species(id: "Epipremnum aureum")
            ?? KnowledgeBaseService.shared.species.first
            ?? PlantSpecies(
                commonName: "Sample Plant",
                scientificName: "Plantus exampleus",
                category: .houseplant,
                propagationMethod: .stemCutting,
                difficulty: .beginner,
                preferredMedium: .water,
                needsRootingHormone: false,
                requiresAerialRoot: false,
                rootTimeWaterDays: 10,
                rootTimeSoilDays: 21,
                cutLocationDescription: "Cut below a node.",
                notes: "Fallback preview species.",
                verify: false
            )
    }
}
