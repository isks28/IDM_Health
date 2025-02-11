//
//  BodyPointsEstimationView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.02.25.
//

import SwiftUI
import Vision

struct BodySkeletonShape: Shape {
    var jointPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]

    private let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
        (.neck, .nose), (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
        (.leftHip, .rightHip)
    ]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for connection in connections {
            if let point1 = jointPoints[connection.0], let point2 = jointPoints[connection.1] {
                path.move(to: CGPoint(x: point1.x * rect.width, y: point1.y * rect.height))
                path.addLine(to: CGPoint(x: point2.x * rect.width, y: point2.y * rect.height))
            }
        }
        return path
    }
}

struct BodyPointsEstimationView: View {
    @StateObject private var bodyPointsEstimationManager = BodyPointsEstimationManager()
    @State private var showingInfo = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let currentFrame = bodyPointsEstimationManager.currentFrame {
                    Image(decorative: currentFrame, scale: 1.0)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color.black
                }
                
                BodySkeletonShape(jointPoints: bodyPointsEstimationManager.jointPoints)
                    .stroke(Color.white, lineWidth: 3)
                
                ForEach(bodyPointsEstimationManager.jointPoints.keys.sorted(by: { $0.rawValue.rawValue < $1.rawValue.rawValue }), id: \ .self) { jointName in
                    if let point = bodyPointsEstimationManager.jointPoints[jointName] {
                        ZStack {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 12, height: 12)
                        }
                        .position(x: point.x * geometry.size.width, y: point.y * geometry.size.height)
                    }
                }
            }
            .onAppear {
                bodyPointsEstimationManager.setupCamera()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingInfo.toggle() }) {
                    Image(systemName: "info.circle")
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Vision Body Pose Estimation Demo")
                            .font(.largeTitle)
                            .multilineTextAlignment(.center)
                            .padding()
                        Text("Using Apple's Vision framework, this view demonstrates 19 unique body points estimation, showing joints and connections in real-time using computer vision technology.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
}
