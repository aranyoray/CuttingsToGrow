import SwiftUI
import AVFoundation

/// The AR Node Scanner: live camera with on-device identification and an
/// overlay marking where to cut.
struct ScannerView: View {
    @StateObject private var camera = CameraService()
    @State private var result: ScanResult?
    @State private var isScanning = false
    @State private var showResultSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                if camera.isAuthorized {
                    CameraPreview(session: camera.session)
                        .ignoresSafeArea()
                } else {
                    cameraPlaceholder
                }

                if let result {
                    NodeOverlay(nodes: result.nodeCandidates)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                VStack {
                    if let result {
                        identificationBanner(result)
                            .padding(.top, 8)
                    } else {
                        Text("Point at a plant, then tap Scan")
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(.top, 8)
                    }
                    Spacer()
                    scanButton
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Node Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .onAppear { camera.start() }
            .onDisappear { camera.stop() }
            .sheet(isPresented: $showResultSheet) {
                if let result {
                    ScanResultView(result: result)
                        .presentationDetents([.medium, .large])
                        .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                }
            }
        }
    }

    private var scanButton: some View {
        Button {
            scan()
        } label: {
            ZStack {
                Circle()
                    .fill(Theme.leaf)
                    .frame(width: 76, height: 76)
                    .shadow(radius: 6)
                if isScanning {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(isScanning || !camera.isAuthorized)
        .accessibilityLabel("Scan plant")
    }

    private func identificationBanner(_ result: ScanResult) -> some View {
        Button { showResultSheet = true } label: {
            HStack(spacing: 10) {
                Image(systemName: result.species != nil ? "checkmark.seal.fill" : "questionmark.circle")
                    .foregroundStyle(result.species != nil ? Theme.sprout : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.species?.commonName ?? "Unrecognized plant")
                        .font(.headline)
                    Text(result.species != nil
                         ? "Glowing rings mark cutting nodes — tap for details"
                         : "Try a closer shot of the leaves and stem")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let species = result.species, species.toxicity.isToxicToAny {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(Theme.warning)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private var cameraPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 56))
                .foregroundStyle(Theme.leaf)
            Text("Camera access is needed to scan plants")
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func scan() {
        guard let frame = camera.captureFrame() else { return }
        isScanning = true
        Task {
            defer { isScanning = false }
            if let scan = try? await PlantClassifierService.shared.classify(ciImage: frame) {
                withAnimation(.spring) { result = scan }
                if scan.species != nil { showResultSheet = true }
            }
        }
    }
}

/// Pulsing rings over detected node positions — "cut here" markers.
struct NodeOverlay: View {
    let nodes: [CGPoint]
    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            ForEach(Array(nodes.enumerated()), id: \.offset) { _, point in
                ZStack {
                    Circle()
                        .stroke(Theme.sprout, lineWidth: 3)
                        .frame(width: pulse ? 56 : 40, height: pulse ? 56 : 40)
                        .opacity(pulse ? 0.3 : 0.9)
                    Image(systemName: "scissors")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Theme.leaf, in: Circle())
                }
                // Vision coordinates are normalized with origin at bottom-left.
                .position(x: point.x * geo.size.width,
                          y: (1 - point.y) * geo.size.height)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
