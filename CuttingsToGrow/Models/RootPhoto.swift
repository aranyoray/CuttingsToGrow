import Foundation
import SwiftData

/// A single dated photo in a cutting's root-progress timeline.
///
/// Image bytes use `.externalStorage`, so SwiftData writes them to files on disk
/// rather than bloating the database — the right call for photo data.
@Model
final class RootPhoto {
    var id: UUID
    var date: Date
    @Attribute(.externalStorage) var imageData: Data
    var caption: String?

    /// Inverse of `Cutting.rootPhotos`.
    var cutting: Cutting?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        imageData: Data,
        caption: String? = nil
    ) {
        self.id = id
        self.date = date
        self.imageData = imageData
        self.caption = caption
    }
}
