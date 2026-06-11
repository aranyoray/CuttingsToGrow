import AVFoundation
import CoreImage
import UIKit

/// Live camera session that publishes frames for the scanner overlay and
/// captures stills for classification.
final class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session")
    private var latestFrame: CIImage?
    private let frameLock = NSLock()

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            configure()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.configure() }
                }
            }
        default:
            isAuthorized = false
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    /// Grab the most recent frame for on-device classification.
    func captureFrame() -> CIImage? {
        frameLock.lock()
        defer { frameLock.unlock() }
        return latestFrame
    }

    private func configure() {
        sessionQueue.async { [self] in
            guard session.inputs.isEmpty else {
                if !session.isRunning { session.startRunning() }
                return
            }
            session.beginConfiguration()
            session.sessionPreset = .photo
            if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
               let input = try? AVCaptureDeviceInput(device: device),
               session.canAddInput(input) {
                session.addInput(input)
            }
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            if session.canAddOutput(videoOutput) {
                session.addOutput(videoOutput)
                videoOutput.connection(with: .video)?.videoRotationAngle = 90
            }
            session.commitConfiguration()
            session.startRunning()
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = CIImage(cvPixelBuffer: buffer)
        frameLock.lock()
        latestFrame = image
        frameLock.unlock()
    }
}
