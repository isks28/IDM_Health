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
        
        DispatchQueue.global(qos: .userInitiated).async {
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

    enum JointAngle: String, CaseIterable {
        case rightShoulderFlexionExtension = "Right Shoulder Flexion/Extension"
        case rightShoulderAbductionAdduction = "Right Shoulder Abduction/Adduction"
        case leftShoulderFlexionExtension = "Left Shoulder Flexion/Extension"
        case leftShoulderAbductionAdduction = "Left Shoulder Abduction/Adduction"
        case rightElbowFlexionExtension = "Right Elbow Flexion/Extension"
        case leftElbowFlexionExtension = "Left Elbow Flexion/Extension"
        case rightHipFlexionExtension = "Right Hip Flexion/Extension"
        case rightHipAbductionAdduction = "Right Hip Abduction/Adduction"
        case leftHipFlexionExtension = "Left Hip Flexion/Extension"
        case leftHipAbductionAdduction = "Left Hip Abduction/Adduction"
        case rightKneeFlexionExtension = "Right Knee Flexion/Extension"
        case leftKneeFlexionExtension = "Left Knee Flexion/Extension"
    }

    func calculateAngle(for jointAngle: JointAngle) -> Double? {
        switch jointAngle {
        case .rightShoulderFlexionExtension:
            return calculateRightShoulderFlexionExtension()
        default:
            return nil
        }
    }

    func calculateRightShoulderFlexionExtension() -> Double? {
        guard let rightShoulder = jointPoints[.rightShoulder],
              let rightElbow = jointPoints[.rightElbow],
              let rightHip = jointPoints[.rightHip] else {
            return nil
        }

        let shoulderToElbow = CGPoint(x: rightElbow.x - rightShoulder.x, y: rightElbow.y - rightShoulder.y)
        let shoulderToHip = CGPoint(x: rightHip.x - rightShoulder.x, y: rightHip.y - rightShoulder.y)

        let angle = atan2(shoulderToElbow.y, shoulderToElbow.x) - atan2(shoulderToHip.y, shoulderToHip.x)
        return abs(angle * (180.0 / .pi)) // Convert to degrees
    }
}
