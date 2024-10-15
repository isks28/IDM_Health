//
//  rawDataAllView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import LocalAuthentication
import CoreMotion
import UserNotifications

enum DataType: String, CaseIterable {
    case accelerometer = "Accelerometer"
    case gyroscope = "Gyroscope"
    case magnetometer = "Magnetometer"
}

struct rawDataAllView: View {
    @StateObject private var motionManager = RawDataAllManager()
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isRecordingRealTime = false
    @State private var isRecordingInterval = false
    @State private var samplingRate: Double = 60.0 // Default sampling rate
    @State private var canControlSamplingRate = false
    @State private var showingAuthenticationError = false
    @State private var selectedDataType: DataType = .accelerometer // Default data type
    
    var body: some View {
        VStack {
            Text("Raw Data All")
                .font(.title)
                .foregroundStyle(Color.primary)
                .padding(.top, 5)
            
            // Segmented Picker to choose data type
            Picker("Select Data", selection: $selectedDataType) {
                ForEach(DataType.allCases, id: \.self) { dataType in
                    Text(dataType.rawValue)
                        .tag(dataType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Spacer()
            
            // Display Graphs Based on Selected Data Type
            switch selectedDataType {
            case .accelerometer:
                if motionManager.userAccelerometerData.last != nil {
                    VStack {
                        RawDataGraphView(
                            dataPoints: motionManager.accelerometerDataPointsX,
                            lineColor: .red,
                            axisLabel: "X-Axis",
                            graphTitle: "Accelerometer X-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.accelerometerDataPointsY,
                            lineColor: .green,
                            axisLabel: "Y-Axis",
                            graphTitle: "Accelerometer Y-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.accelerometerDataPointsZ,
                            lineColor: .blue,
                            axisLabel: "Z-Axis",
                            graphTitle: "Accelerometer Z-Axis"
                        )
                        .frame(height: 100)
                    }
                } else {
                    Text("Set the desired Time")
                        .padding(.bottom, 300)
                        .font(.headline)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                
            case .gyroscope:
                if motionManager.rotationalData.last != nil {
                    VStack {
                        RawDataGraphView(
                            dataPoints: motionManager.rotationalDataPointsX,
                            lineColor: .red,
                            axisLabel: "X-Axis",
                            graphTitle: "Gyroscope X-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.rotationalDataPointsY,
                            lineColor: .green,
                            axisLabel: "Y-Axis",
                            graphTitle: "Gyroscope Y-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.rotationalDataPointsZ,
                            lineColor: .blue,
                            axisLabel: "Z-Axis",
                            graphTitle: "Gyroscope Z-Axis"
                        )
                        .frame(height: 100)
                    }
                } else {
                    Text("Set the desired Time")
                        .padding(.bottom, 300)
                        .font(.headline)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                
            case .magnetometer:
                if motionManager.magneticFieldData.last != nil {
                    VStack {
                        RawDataGraphView(
                            dataPoints: motionManager.magneticDataPointsX,
                            lineColor: .red,
                            axisLabel: "X-Axis",
                            graphTitle: "Magnetometer X-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.magneticDataPointsY,
                            lineColor: .green,
                            axisLabel: "Y-Axis",
                            graphTitle: "Magnetometer Y-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.magneticDataPointsZ,
                            lineColor: .blue,
                            axisLabel: "Z-Axis",
                            graphTitle: "Magnetometer Z-Axis"
                        )
                        .frame(height: 100)
                    }
                } else {
                    Text("Set the desired Time")
                        .padding(.bottom, 300)
                        .font(.headline)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
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
                        motionManager.stopRawDataAllCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        motionManager.stopRawDataAllCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingRealTime = false
                        }
                    }
            }
            .padding()
            
            VStack {
                if isRecordingInterval && !isRecording {
                    DatePicker("Start Date and Time", selection: $startDate)
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("End Date and Time", selection: $endDate)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                HStack {
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
                                let serverURL = ServerConfig.serverURL  // Update this URL as needed

                                motionManager.scheduleDataCollection(startDate: startDate, endDate: endDate, serverURL: serverURL, baseFolder: "RawDataAll") {
                                    DispatchQueue.main.async {
                                        isRecording = false
                                        motionManager.removeDataCollectionNotification() // Remove notification when recording stops
                                    }
                                }
                                motionManager.showDataCollectionNotification() // Show notification on start
                            } else {
                                motionManager.stopRawDataAllCollection()
                                motionManager.removeDataCollectionNotification() // Remove notification on stop
                            }
                        }
                        
                        if motionManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color(.blue))
                        }
                    }
                }
                
                HStack {
                    if isRecordingRealTime {
                        Button(action: {
                            motionManager.savedFilePath = nil // Reset "File saved" text when starting a new recording
                            
                            if isRecording {
                                motionManager.stopRawDataAllCollection()
                                motionManager.removeDataCollectionNotification() // Remove notification on stop
                                // Define the server URL
                                let serverURL = ServerConfig.serverURL  // Update this URL as needed
                                motionManager.saveDataToCSV(serverURL: serverURL, baseFolder: "RawDataAll", recordingMode: "RealTime")
                            } else {
                                let serverURL = ServerConfig.serverURL
                                
                                motionManager.startRawDataAllCollection(realTime: true, serverURL: serverURL)
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
                            Text("File saved")
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

// Custom RawDataGraphView to display one axis at a time
struct RawDataGraphView: View {
    var dataPoints: [Double]
    var lineColor: Color
    var axisLabel: String
    var graphTitle: String
    
    var body: some View {
        VStack {
            Text(graphTitle)
                .font(.title3)
                .padding(.bottom, 5)
            
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
            
            Text(axisLabel)
                .font(.caption)
                .foregroundColor(lineColor)
                .padding(.top, 2)
        }
    }
}

#Preview {
    rawDataAllView()
}
