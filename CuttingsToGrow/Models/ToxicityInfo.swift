import Foundation

/// Pet-toxicity facts for one species — the flagship safety data of the app.
///
/// Loaded from the standalone `toxicity.json` (see `ToxicityService`) and joined
/// onto `PlantSpecies` by scientific name. Keeping toxicity in its own dataset
/// makes the safety information easy to audit and cite, and mirrors how the ASPCA
/// publishes solid cats/dogs coverage with small pets where reliable.
///
/// `toxicToSmallPets` is optional: `nil` means "not reliably known", which is
/// treated as *unknown*, never as "safe".
struct ToxicityInfo: Codable, Hashable {
    let scientificName: String
    let commonName: String
    let toxicToCats: Bool
    let toxicToDogs: Bool
    let toxicToSmallPets: Bool?
    let severityNote: String
    let source: String
    /// True when we could not confirm this entry; the UI shows a "verify" note.
    let verify: Bool

    /// Any *confirmed* toxicity. Unknown small-pet data (`nil`) does not count as toxic.
    var isToxicToAnyPet: Bool {
        toxicToCats || toxicToDogs || (toxicToSmallPets ?? false)
    }

    /// Lower-cased pet names this species is known to be toxic to.
    var affectedPets: [String] {
        var pets: [String] = []
        if toxicToCats { pets.append("cats") }
        if toxicToDogs { pets.append("dogs") }
        if toxicToSmallPets == true { pets.append("small pets") }
        return pets
    }

    /// A short banner-ready summary, e.g. "Toxic to cats and dogs".
    var headline: String {
        if isToxicToAnyPet {
            return "Toxic to \(affectedPets.joined(separator: " and "))"
        } else {
            return "Pet safe"
        }
    }

    /// Fallback used when a species has no toxicity record at all. Errs on the
    /// side of caution: unknown, flagged to verify, and not asserted safe.
    static func unknown(for species: PlantSpecies) -> ToxicityInfo {
        ToxicityInfo(
            scientificName: species.scientificName,
            commonName: species.commonName,
            toxicToCats: false,
            toxicToDogs: false,
            toxicToSmallPets: nil,
            severityNote: "No toxicity record was found for this species. Treat it as unverified and keep it away from pets until you can check a trusted source.",
            source: "None",
            verify: true
        )
    }
}
