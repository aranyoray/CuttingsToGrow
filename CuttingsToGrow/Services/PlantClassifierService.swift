import Vision
import CoreImage
import simd

struct ScanResult {
    let species: PlantSpecies?
    let rawLabel: String
    let confidence: Float
    let nodeCandidates: [CGPoint] // normalized (0–1) image coordinates
}

/// On-device plant identification built on Apple's Vision framework.
///
/// `VNClassifyImageRequest` ships inside iOS with a 1,300+ class taxonomy that
/// includes a large block of plant species and genera — no model download, no
/// network call, and inference runs on the Neural Engine. Labels are matched
/// against `PlantDatabase` for propagation triage. The architecture isolates
/// classification behind this service so the built-in classifier can be swapped
/// for a bundled Core ML model (e.g. a PlantNet-300K MobileNetV3 conversion)
/// without touching any view code.
final class PlantClassifierService {
    static let shared = PlantClassifierService()
    private init() {}

    func classify(ciImage: CIImage) async throws -> ScanResult {
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        let classifyRequest = VNClassifyImageRequest()
        let saliencyRequest = VNGenerateAttentionBasedSaliencyImageRequest()
        let contourRequest = VNDetectContoursRequest()
        contourRequest.contrastAdjustment = 1.5
        contourRequest.detectsDarkOnLight = true

        try handler.perform([classifyRequest, saliencyRequest, contourRequest])

        let plantObservations = (classifyRequest.results ?? [])
            .filter { $0.confidence > 0.1 }
            .sorted { $0.confidence > $1.confidence }

        // Prefer the highest-confidence label that maps to a known species.
        let best = plantObservations.first { PlantDatabase.match(classifierLabel: $0.identifier) != nil }
            ?? plantObservations.first

        let label = best?.identifier ?? "unknown"
        let species = PlantDatabase.match(classifierLabel: label)

        let nodes = nodeCandidates(
            saliency: saliencyRequest.results?.first,
            contours: contourRequest.results?.first
        )

        return ScanResult(
            species: species,
            rawLabel: label,
            confidence: best?.confidence ?? 0,
            nodeCandidates: nodes
        )
    }

    /// Heuristic node localization for the AR overlay: nodes sit where stems
    /// branch, which shows up as high-curvature junctions along the dominant
    /// contours inside the salient (plant) region. This is intentionally
    /// approximate — the overlay teaches users *what* a node looks like and
    /// the guidance text tells them how far below it to cut.
    private func nodeCandidates(
        saliency: VNSaliencyImageObservation?,
        contours: VNContoursObservation?
    ) -> [CGPoint] {
        let salientRect = saliency?.salientObjects?.first?.boundingBox
            ?? CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)

        guard let contours else {
            return fallbackPoints(in: salientRect)
        }

        var junctions: [CGPoint] = []
        for i in 0..<min(contours.contourCount, 12) {
            guard let contour = try? contours.contour(at: i),
                  contour.normalizedPoints.count >= 9 else { continue }
            let pts = contour.normalizedPoints
            // Sample curvature along the contour; sharp direction changes
            // inside the salient region are branch-junction candidates.
            let stride = max(pts.count / 24, 1)
            for j in Swift.stride(from: stride, to: pts.count - stride, by: stride) {
                let a = pts[j - stride], b = pts[j], c = pts[j + stride]
                let v1 = simd_normalize(simd_float2(b.x - a.x, b.y - a.y))
                let v2 = simd_normalize(simd_float2(c.x - b.x, c.y - b.y))
                let turn = simd_dot(v1, v2)
                let point = CGPoint(x: CGFloat(b.x), y: CGFloat(b.y))
                if turn < 0.3, salientRect.contains(point) {
                    junctions.append(point)
                }
            }
        }

        // De-duplicate clustered junctions and cap the overlay at 5 markers.
        var picked: [CGPoint] = []
        for p in junctions {
            if picked.allSatisfy({ hypot($0.x - p.x, $0.y - p.y) > 0.12 }) {
                picked.append(p)
            }
            if picked.count == 5 { break }
        }
        return picked.isEmpty ? fallbackPoints(in: salientRect) : picked
    }

    private func fallbackPoints(in rect: CGRect) -> [CGPoint] {
        // Lower third of the salient region — where nodes typically are on a stem.
        [
            CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.30),
            CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.15)
        ]
    }
}
