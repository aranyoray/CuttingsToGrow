import Foundation

/// Loads and serves the bundled pet-toxicity dataset (`toxicity.json`).
///
/// Pet safety is the flagship feature of Cuttings Garden, and it runs entirely
/// offline: the facts ship with the app. This service exposes a fast lookup by
/// scientific name, which `KnowledgeBaseService` uses to join toxicity onto each
/// species.
final class ToxicityService {
    static let shared = ToxicityService()

    /// Toxicity records keyed by scientific name.
    private(set) var byScientificName: [String: ToxicityInfo] = [:]

    /// Matches the top-level shape of `toxicity.json`.
    private struct File: Decodable {
        let entries: [ToxicityInfo]
    }

    private init() { load() }

    private func load() {
        do {
            let file = try BundleLoader.decode(File.self, from: "toxicity")
            // reduce(into:) tolerates a duplicate key without crashing (last wins).
            byScientificName = file.entries.reduce(into: [:]) { dict, entry in
                dict[entry.scientificName] = entry
            }
        } catch {
            print("⚠️ ToxicityService failed to load: \(error)")
        }
    }

    func toxicity(for scientificName: String) -> ToxicityInfo? {
        byScientificName[scientificName]
    }
}
