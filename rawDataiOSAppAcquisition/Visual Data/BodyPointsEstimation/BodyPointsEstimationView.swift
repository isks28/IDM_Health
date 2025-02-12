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
    @State private var selectedAngle: BodyPointsEstimationManager.JointAngle = .rightShoulderFlexionExtension
    @State private var displayedAngle: Double? = nil
    @State private var timer: Timer? = nil

    let categories: [String: [BodyPointsEstimationManager.JointAngle]] = [
        "Shoulder": [.rightShoulderFlexionExtension, .rightShoulderAbductionAdduction, .leftShoulderFlexionExtension, .leftShoulderAbductionAdduction],
        "Elbow": [.rightElbowFlexionExtension, .leftElbowFlexionExtension],
        "Hip": [.rightHipFlexionExtension, .rightHipAbductionAdduction, .leftHipFlexionExtension, .leftHipAbductionAdduction],
        "Knee": [.rightKneeFlexionExtension, .leftKneeFlexionExtension]
    ]

    @State private var expandedCategory: String? = nil
    @State private var isMenuVisible = false

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

                VStack {
                    if let angleValue = displayedAngle {
                        Text("\(selectedAngle.rawValue): \(String(format: "%.2f", angleValue)) °")
                            .font(.title)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .foregroundColor(.black)
                            .padding(.top, 20)
                    }

                    Spacer()
                    ZStack(alignment: .bottom) {
                        if isMenuVisible {
                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(categories.keys.sorted(), id: \ .self) { category in
                                    Button(action: {
                                        withAnimation(.none) {
                                            if expandedCategory == category {
                                                expandedCategory = nil
                                            } else {
                                                expandedCategory = category
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Text(category)
                                                .font(.title2)
                                                .foregroundStyle(Color.white)
                                                .padding()
                                                .background(Color.blue.opacity(0.75))
                                                .cornerRadius(15)
                                            Spacer()
                                            Image(systemName: expandedCategory == category ? "chevron.up" : "chevron.down")
                                                .foregroundStyle(Color.blue.opacity(0.75))
                                        }
                                    }
                                    
                                    if expandedCategory == category {
                                        ForEach(categories[category]!, id: \ .self) { angle in
                                            Button(action: {
                                                selectedAngle = angle
                                                isMenuVisible = false
                                                expandedCategory = nil
                                            }) {
                                                Text(angle.rawValue)
                                                    .font(.headline)
                                                    .foregroundStyle(Color.white)
                                                    .padding()
                                                    .background(Color.blue.opacity(0.75))
                                                    .cornerRadius(15)
                                            }
                                            .padding(.leading, 35)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                            .offset(y: -80)
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.none) {
                                isMenuVisible.toggle()
                            }
                        }) {
                            Image(systemName: "angle")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .padding(12)
                                .background(Color.blue.opacity(0.75))
                                .clipShape(Circle())
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isMenuVisible {
                    isMenuVisible = false
                    expandedCategory = nil
                }
            }
            .onAppear {
                bodyPointsEstimationManager.setupCamera()
                timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    displayedAngle = bodyPointsEstimationManager.calculateAngle(for: selectedAngle)
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
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
