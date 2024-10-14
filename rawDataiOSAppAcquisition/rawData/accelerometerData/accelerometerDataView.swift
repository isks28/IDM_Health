//
//  accelerometerDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import LocalAuthentication
import UserNotifications

struct accelerometerDataView: View {
    @StateObject private var motionManager = AccelerometerManager()
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isRecordingRealTime = false
    @State private var isRecordingInterval = false
    @State private var samplingRate: Double = 60.0 // Default sampling rate
    
    @State private var canControlSamplingRate = false
    @State private var showingAuthenticationError = false
    
    var body: some View {
        VStack {
            Text("Accelerometer")
                .font(.title)
                .foregroundStyle(Color.primary)
                .padding(.top, 5)
            Spacer()
            
            if motionManager.accelerometerData.last != nil {
                Text("UserAcceleration Data")
                    .font(.title2)
                    .foregroundStyle(Color.pink)
                    .padding()
            } else {
                Text("Set the desired Time")
                    .padding()
                    .font(.headline)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Simple Graph View
            VStack {
                if motionManager.accelerometerData.last != nil {
                    Text("X-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                AccelerometerGraphView(dataPoints: motionManager.accelerometerDataPointsX, lineColor: .red.opacity(0.5))
                    .frame(height: 90)
                
                if motionManager.accelerometerData.last != nil {
                    Text("Y-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                AccelerometerGraphView(dataPoints: motionManager.accelerometerDataPointsY, lineColor: .green.opacity(0.5))
                    .frame(height: 90)
                
                if motionManager.accelerometerData.last != nil {
                    Text("Z-Axis")
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                }
                AccelerometerGraphView(dataPoints: motionManager.accelerometerDataPointsZ, lineColor: .blue.opacity(0.5))
                    .frame(height: 90)
            }
            
            if !isRecording && !isRecordingInterval && !isRecordingRealTime {
                VStack {
                    Toggle(isOn: $canControlSamplingRate) {
                        Text("Enable Sampling Rate Control")
                        Text("Default: 60Hz")
                            .font(.caption2)
                    }
                    .onChange(of: canControlSamplingRate) { _, newValue in
                        if newValue {
                            authenticateUser { success in
                                if !success {
                                    canControlSamplingRate = false
                                    showingAuthenticationError = true
                                } else {
                                    showingAuthenticationError = false
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            if canControlSamplingRate && !isRecording && !isRecordingInterval && !isRecordingRealTime {
                VStack {
                    Text("Sampling Rate: \(Int(samplingRate)) Hz")
                    Slider(value: $samplingRate, in: 5...100, step: 5)
                        .padding()
                        .onChange(of: samplingRate) { oldRate, newRate in
                            motionManager.updateSamplingRate(rate: newRate)
                        }
                }
            }
            
            if showingAuthenticationError && !isRecording && !isRecordingInterval && !isRecordingRealTime {
                Text("Authentication Failed. Unable to control sampling rate.")
                    .foregroundColor(.red)
                    .font(.caption2)
            }
            
            HStack {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { _, newValue in
                        isRecording = false
                        motionManager.stopAccelerometerDataCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        motionManager.stopAccelerometerDataCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingRealTime = false
                        }
                    }
            }
            .padding()
            
            VStack {
                // Timed interval recording
                if isRecordingInterval && !isRecording {
                    DatePicker("Start Date and Time", selection: $startDate)
                        .datePickerStyle(CompactDatePickerStyle())

                    DatePicker("End Date and Time", selection: $endDate)
                        .datePickerStyle(CompactDatePickerStyle())
                }

                HStack {
                    // Toggle for timed recording
                    if isRecordingInterval {
                        Toggle(isOn: $isRecording) {
                            Text(isRecording ? "Data will be fetched according to set time interval" : "Start timed recording")
                                .padding()
                                .background(isRecording ? Color.mint : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .multilineTextAlignment(.center)
                        }
                        .onChange(of: isRecording) { _, newValue in
                            motionManager.savedFilePath = nil // Reset "File saved" text

                            if newValue {
                                // Define the server URL
                                let serverURL = URL(string: "http://192.168.0.199:8888")!  // Update this URL as needed

                                motionManager.scheduleDataCollection(startDate: startDate, endDate: endDate, serverURL: serverURL) {
                                    DispatchQueue.main.async {
                                        isRecording = false
                                        motionManager.removeDataCollectionNotification() // Remove notification when recording stops
                                    }
                                }
                                motionManager.showDataCollectionNotification() // Show notification on start
                            } else {
                                motionManager.stopAccelerometerDataCollection()
                                motionManager.removeDataCollectionNotification() // Remove notification on stop
                            }
                        }

                        if motionManager.savedFilePath != nil {
                            Text("File saved at \(motionManager.savedFilePath ?? "")")  // Display the saved file path
                                .font(.footnote)
                                .foregroundStyle(Color(.blue))
                        }
                    }
                }

                HStack {
                    // Real-time recording
                    if isRecordingRealTime {
                        Button(action: {
                            motionManager.savedFilePath = nil // Reset "File saved" text when starting a new recording

                            if isRecording {
                                motionManager.stopAccelerometerDataCollection()
                                motionManager.removeDataCollectionNotification() // Remove notification on stop
                                
                                // Define the server URL
                                let serverURL = URL(string: "http://192.168.0.199:8888")!  // Update this URL as needed
                                motionManager.saveDataToCSV(serverURL: serverURL, baseFolder: "RealTimeData")
                            } else {
                                let serverURL = URL(string: "http://192.168.0.199:8888")!
                                
                                motionManager.startAccelerometerDataCollection(realTime: true, serverURL: serverURL)
                                motionManager.showDataCollectionNotification() // Show notification on start
                            }
                            isRecording.toggle()
                        }) {
                            Text(isRecording ? "Stop and Save" : "Start")
                                .padding()
                                .background(isRecording ? Color.gray : Color.mint)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }

                        if motionManager.savedFilePath != nil {
                            Text("File saved at \(motionManager.savedFilePath ?? "")")
                                .font(.footnote)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // Function to authenticate the user using Face ID/Touch ID or passcode
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to enable sampling rate control."
            
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        } else {
            completion(false)
        }
    }
}

struct AccelerometerGraphView: View {
    var dataPoints: [Double]
    var lineColor: Color

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard dataPoints.count > 1 else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let maxValue = dataPoints.max() ?? 1
                let minValue = dataPoints.min() ?? 0
                let scaleX = width / CGFloat(dataPoints.count - 1)
                let scaleY = height / CGFloat(maxValue - minValue)

                path.move(to: CGPoint(x: 0, y: height - CGFloat(dataPoints[0] - minValue) * scaleY))
                
                for index in 1..<dataPoints.count {
                    let x = CGFloat(index) * scaleX
                    let y = height - CGFloat(dataPoints[index] - minValue) * scaleY
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(lineColor, lineWidth: 2)
        }
    }
}

#Preview {
    accelerometerDataView()
}
