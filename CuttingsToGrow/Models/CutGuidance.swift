import CoreGraphics
import Foundation

/// The derived cut/trim advice the `CutAdvisor` produces from a set of
/// `AnatomyDetection`s plus the identified species' profile (Phase 3).
///
/// This is **not** emitted by the model — it is the app's reasoning layer, which
/// is what keeps the "where to cut" logic explainable and the model simple. It is
/// a value type and is never persisted.
struct CutGuidance: Hashable {
    /// Where to snip, derived (e.g. just below the lowest node). Vision-normalized.
    var cutPointRect: CGRect?
    /// Leaves the advisor recommends trimming (the yellowing/dead ones).
    var trimRects: [CGRect]
    /// Plain-English steps shown under the photo, e.g.
    /// "Cut ~1 cm below the marked node" / "Trim the 2 yellowing leaves".
    var humanReadableSteps: [String]
    /// A single confidence value summarising the detections the advice rests on.
    var overallConfidence: Float

    static let empty = CutGuidance(
        cutPointRect: nil,
        trimRects: [],
        humanReadableSteps: [],
        overallConfidence: 0
    )
}
