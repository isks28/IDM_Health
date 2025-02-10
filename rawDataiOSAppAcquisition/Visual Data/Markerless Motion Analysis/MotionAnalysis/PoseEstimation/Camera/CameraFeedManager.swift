import AVFoundation
import Accelerate.vImage
import UIKit

protocol CameraFeedManagerDelegate: AnyObject {
  func cameraFeedManager(
    _ cameraFeedManager: CameraFeedManager, didOutput pixelBuffer: CVPixelBuffer)
}

final class CameraFeedManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

  weak var delegate: CameraFeedManagerDelegate?
  private let captureSession = AVCaptureSession()

  override init() {
    super.init()
    configureSession()
  }

  /// Start capturing frames from the camera.
  func startRunning() {
    DispatchQueue.main.async {
      if !self.captureSession.isRunning {
        self.captureSession.startRunning()
      }
    }
  }

  /// Stop capturing frames from the camera.
  func stopRunning() {
    DispatchQueue.main.async {
      if self.captureSession.isRunning {
        self.captureSession.stopRunning()
      }
    }
  }

  private func configureSession() {
    captureSession.sessionPreset = .high // Set a higher preset if frame rate allows.

    guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
      print("Error: Unable to access front camera.")
      return
    }

    do {
      let input = try AVCaptureDeviceInput(device: frontCamera)
      if captureSession.canAddInput(input) {
        captureSession.addInput(input)
      }
    } catch {
      print("Error: Unable to initialize front camera: \(error.localizedDescription)")
      return
    }

    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.videoSettings = [
      (kCVPixelBufferPixelFormatTypeKey as String): NSNumber(value: kCVPixelFormatType_32BGRA)
    ]
    videoOutput.alwaysDiscardsLateVideoFrames = true
    
    let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated)
    
    if captureSession.canAddOutput(videoOutput) {
      captureSession.addOutput(videoOutput)
      if let connection = videoOutput.connection(with: .video) {
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = true // Enable mirroring for the front camera
      }
    } else {
      print("Error: Unable to add video output.")
      return
    }

    videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
  }

  func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
    CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
    delegate?.cameraFeedManager(self, didOutput: pixelBuffer)
    CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags.readOnly)
  }
}

