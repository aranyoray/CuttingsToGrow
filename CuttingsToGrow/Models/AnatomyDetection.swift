import CoreGraphics
import Foundation

/// One anatomy box produced by a `PlantAnatomyDetector`.
///
/// This struct is the **model I/O contract** (see `Docs/MODEL_TRAINING.md`). The
/// author's trained Core ML model and the Mock detector will both return arrays
/// of `AnatomyDetection`, and the app's `CutAdvisor` turns them into cut/trim
/// guidance (both arrive in Phase 3).
///
/// The key design rule lives here: the model only ever reports *anatomy* — a
/// `node`, an `aerialRoot`, a `deadOrYellowingLeaf`. It never reports "cut here".
/// All cut/trim reasoning is app code, so it stays explainable and the model
/// stays a simple, trainable object detector. `confidence` is always surfaced in
/// the UI; we never imply certainty the model doesn't have.
struct AnatomyDetection: Identifiable, Hashable {
    /// The v1 anatomy classes — deliberately tight so one student can label and
    /// train them. (v2 could add `growthTip`, `stem`.)
    enum Kind: String, CaseIterable {
        case node
        case aerialRoot
        case deadOrYellowingLeaf

        var displayName: String {
            switch self {
            case .node: return "Node"
            case .aerialRoot: return "Aerial root"
            case .deadOrYellowingLeaf: return "Yellowing leaf"
            }
        }
    }

    let id: UUID
    let kind: Kind
    /// Detector confidence, 0...1. ALWAYS shown to the user.
    let confidence: Float
    /// Vision-normalized rectangle: coordinates in 0...1 with the origin at the
    /// bottom-left (Vision's convention). The overlay flips Y to draw it.
    let boundingBox: CGRect

    init(id: UUID = UUID(), kind: Kind, confidence: Float, boundingBox: CGRect) {
        self.id = id
        self.kind = kind
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}
