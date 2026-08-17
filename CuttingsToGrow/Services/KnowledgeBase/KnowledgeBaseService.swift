import Foundation

/// Loads the propagation knowledge base and joins the flagship toxicity data onto
/// each species by scientific name. This is the app's read-only plant "catalog".
///
/// The join is the interesting bit: the knowledge base describes *how to grow* a
/// species, while the separate `toxicity.json` describes *whether it's dangerous*
/// to pets. Keeping them in two files makes the safety dataset easy to audit; we
/// stitch them into one rich `PlantSpecies` here, at load time.
final class KnowledgeBaseService {
    static let shared = KnowledgeBaseService()

    /// All species, sorted by common name and with toxicity joined in.
    private(set) var species: [PlantSpecies] = []
    private var byID: [String: PlantSpecies] = [:]

    /// Matches the top-level shape of `propagation_knowledge_base.json`.
    private struct File: Decodable {
        let species: [PlantSpecies]
    }

    private init() { load() }

    private func load() {
        do {
            var loaded = try BundleLoader.decode(File.self, from: "propagation_knowledge_base").species
            // Join the flagship toxicity dataset onto each species.
            for index in loaded.indices {
                loaded[index].toxicity = ToxicityService.shared.toxicity(for: loaded[index].scientificName)
            }
            loaded.sort { $0.commonName.localizedCaseInsensitiveCompare($1.commonName) == .orderedAscending }
            species = loaded
            byID = loaded.reduce(into: [:]) { dict, item in dict[item.id] = item }
        } catch {
            print("⚠️ KnowledgeBaseService failed to load: \(error)")
        }
    }

    /// Look a species up by its id (scientific name).
    func species(id: String) -> PlantSpecies? { byID[id] }

    /// Species grouped by category, for sectioned pickers (Phases 1–2).
    func speciesByCategory() -> [(category: PlantCategory, species: [PlantSpecies])] {
        PlantCategory.allCases.compactMap { category in
            let items = species.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }
}
