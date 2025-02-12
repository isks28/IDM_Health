//
//  BodyPointsEstimationManager.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.02.25.
//

import AVFoundation
import Vision
import SwiftUI
import Combine
import Foundation

class BodyPointsEstimationManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var currentFrame: CGImage?
    @Published var jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    override init() {
        super.init()
        setupCamera()
    }
    
    public func setupCamera() {
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvImageBuffer: pixelBuffer)
        let context = CIContext()
        
        let transform = CGAffineTransform(rotationAngle: -.pi / 2)
            .translatedBy(x: -ciImage.extent.height, y: 0)
            .scaledBy(x: 1, y: -1)
        
        let orientedImage = ciImage.transformed(by: transform)
        
        guard let cgImage = context.createCGImage(orientedImage, from: orientedImage.extent) else { return }
        
        DispatchQueue.main.async {
            self.currentFrame = cgImage
            self.estimateBodyPose(from: cgImage)
        }
    }
    
    private func estimateBodyPose(from cgImage: CGImage) {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([bodyPoseRequest])
            if let observation = bodyPoseRequest.results?.first {
                processObservation(observation)
            }
        } catch {
            print("Failed to perform body pose request: \(error.localizedDescription)")
        }
    }
    
    private func processObservation(_ observation: VNHumanBodyPoseObservation) {
        do {
            let recognizedPoints = try observation.recognizedPoints(.all)
            var jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
            
            for (jointName, point) in recognizedPoints where point.confidence > 0.3 {
                jointPoints[jointName] = CGPoint(x: point.location.x, y: 1 - point.location.y)
            }
            
            DispatchQueue.main.async {
                self.jointPoints = jointPoints
            }
        } catch {
            print("Error recognizing body points: \(error.localizedDescription)")
        }
    }
}
