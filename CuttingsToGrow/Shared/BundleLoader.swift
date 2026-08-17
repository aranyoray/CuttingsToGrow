import Foundation

/// Small helper for decoding bundled JSON resources with clear, debuggable errors.
///
/// Every dataset in the app (knowledge base, toxicity, seed listings, sample-image
/// manifest) is a JSON file in `Resources/`. This centralises the "find the file,
/// read it, decode it" dance so each service stays a few lines long.
enum BundleLoader {
    enum LoadError: Error, CustomStringConvertible {
        case missing(String)
        case decoding(String, Error)

        var description: String {
            switch self {
            case .missing(let name):
                return "Bundled resource '\(name)' was not found in the app bundle."
            case .decoding(let name, let error):
                return "Failed to decode '\(name)': \(error)"
            }
        }
    }

    /// Decode a bundled JSON file by name (without extension). Throws a
    /// descriptive `LoadError` if the file is missing or malformed.
    static func decode<T: Decodable>(
        _ type: T.Type = T.self,
        from name: String,
        extension ext: String = "json",
        bundle: Bundle = .main
    ) throws -> T {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw LoadError.missing("\(name).\(ext)")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LoadError.decoding("\(name).\(ext)", error)
        }
    }
}
