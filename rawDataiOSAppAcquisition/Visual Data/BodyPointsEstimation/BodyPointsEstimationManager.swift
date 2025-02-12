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
        guard let neck = jointPoints[.neck],
              let hip = jointPoints[.root] else { return nil }

        let sagittalPlaneVector = CGPoint(x: hip.x - neck.x, y: hip.y - neck.y)
        let frontalPlaneVector = CGPoint(x: sagittalPlaneVector.y, y: -sagittalPlaneVector.x)

        switch jointAngle {
        case .rightShoulderFlexionExtension, .leftShoulderFlexionExtension,
             .rightElbowFlexionExtension, .leftElbowFlexionExtension,
             .rightHipFlexionExtension, .leftHipFlexionExtension,
             .rightKneeFlexionExtension, .leftKneeFlexionExtension:
            return calculateAngleBetween(joint1: jointStartPoint(for: jointAngle), joint2: jointEndPoint(for: jointAngle), referenceVector: sagittalPlaneVector, isFrontal: false)

        case .rightShoulderAbductionAdduction, .leftShoulderAbductionAdduction,
             .rightHipAbductionAdduction, .leftHipAbductionAdduction:
            return calculateAngleBetween(joint1: jointStartPoint(for: jointAngle), joint2: jointEndPoint(for: jointAngle), referenceVector: frontalPlaneVector, isFrontal: true)
        }
    }

    private func jointStartPoint(for jointAngle: JointAngle) -> VNHumanBodyPoseObservation.JointName {
        switch jointAngle {
        case .rightShoulderFlexionExtension, .rightShoulderAbductionAdduction: return .rightShoulder
        case .leftShoulderFlexionExtension, .leftShoulderAbductionAdduction: return .leftShoulder
        case .rightElbowFlexionExtension: return .rightElbow
        case .leftElbowFlexionExtension: return .leftElbow
        case .rightHipFlexionExtension, .rightHipAbductionAdduction: return .rightHip
        case .leftHipFlexionExtension, .leftHipAbductionAdduction: return .leftHip
        case .rightKneeFlexionExtension: return .rightKnee
        case .leftKneeFlexionExtension: return .leftKnee
        }
    }

    private func jointEndPoint(for jointAngle: JointAngle) -> VNHumanBodyPoseObservation.JointName {
        switch jointAngle {
        case .rightShoulderFlexionExtension, .rightShoulderAbductionAdduction: return .rightElbow
        case .leftShoulderFlexionExtension, .leftShoulderAbductionAdduction: return .leftElbow
        case .rightElbowFlexionExtension: return .rightWrist
        case .leftElbowFlexionExtension: return .leftWrist
        case .rightHipFlexionExtension, .rightHipAbductionAdduction: return .rightKnee
        case .leftHipFlexionExtension, .leftHipAbductionAdduction: return .leftKnee
        case .rightKneeFlexionExtension: return .rightAnkle
        case .leftKneeFlexionExtension: return .leftAnkle
        }
    }

    private func calculateAngleBetween(joint1: VNHumanBodyPoseObservation.JointName, joint2: VNHumanBodyPoseObservation.JointName, referenceVector: CGPoint, isFrontal: Bool) -> Double? {
        guard let point1 = jointPoints[joint1], let point2 = jointPoints[joint2] else { return nil }

        let limbVector = CGPoint(x: point2.x - point1.x, y: point2.y - point1.y)

        let dotProduct = (limbVector.x * referenceVector.x) + (limbVector.y * referenceVector.y)
        let magnitudeLimb = sqrt(pow(limbVector.x, 2) + pow(limbVector.y, 2))
        let magnitudeReference = sqrt(pow(referenceVector.x, 2) + pow(referenceVector.y, 2))

        guard magnitudeLimb != 0 && magnitudeReference != 0 else { return nil }

        let angle = acos(max(min(dotProduct / (magnitudeLimb * magnitudeReference), 1.0), -1.0))

        let adjustedAngle = (angle * (180.0 / .pi))

        return adjustedAngle
    }
}
