import UIKit

/// One bundled sample image, described by `sample_images_manifest.json`.
struct SampleImage: Identifiable, Decodable {
    var id: String { fileName }
    /// Bundled image name, without extension (e.g. "pothos").
    let fileName: String
    /// The species this image depicts (a scientific name in the knowledge base).
    let speciesID: String
    let caption: String

    /// The loaded image, if present in the bundle.
    var image: UIImage? { UIImage(named: fileName) }
}

/// Loads the bundled sample images so the whole Scan → detect → overlay flow can
/// run in the iOS Simulator, which has no camera. These are placeholders until
/// the author drops in real photos (see `Resources/SampleImages/README.md`).
final class SampleImageLibrary {
    static let shared = SampleImageLibrary()

    private(set) var images: [SampleImage] = []

    private struct File: Decodable {
        let images: [SampleImage]
    }

    private init() {
        do {
            images = try BundleLoader.decode(File.self, from: "sample_images_manifest").images
        } catch {
            print("⚠️ SampleImageLibrary failed to load: \(error)")
        }
    }

    /// The sample image for a species, if one is bundled.
    func image(forSpeciesID id: String) -> SampleImage? {
        images.first { $0.speciesID == id }
    }
}
