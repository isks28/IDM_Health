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
    
    @State private var showingInfo = false
    // New state to trigger the graph refresh
    @State private var refreshGraph = UUID()
    
    var body: some View {
        VStack {
            
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
                            lineColor: .red.opacity(0.5),
                            graphTitle: "User Acceleration X-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.accelerometerDataPointsY,
                            lineColor: .green.opacity(0.5),
                            graphTitle: "User Acceleration Y-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.accelerometerDataPointsZ,
                            lineColor: .blue.opacity(0.5),
                            graphTitle: "User Acceleration Z-Axis"
                        )
                        .frame(height: 100)
                    }
                } else {
                    Text("No data")
                        .padding(.bottom, 300)
                        .font(.title3)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                
            case .gyroscope:
                if motionManager.rotationalData.last != nil {
                    VStack {
                        RawDataGraphView(
                            dataPoints: motionManager.rotationalDataPointsX,
                            lineColor: .red.opacity(0.5),
                            graphTitle: "Rotation Rate X-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.rotationalDataPointsY,
                            lineColor: .green.opacity(0.5),
                            graphTitle: "Rotation Rate Y-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.rotationalDataPointsZ,
                            lineColor: .blue.opacity(0.5),
                            graphTitle: "Rotation Rate Z-Axis"
                        )
                        .frame(height: 100)
                    }
                } else {
                    Text("No data")
                        .padding(.bottom, 300)
                        .font(.title3)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
                
            case .magnetometer:
                if motionManager.magneticFieldData.last != nil {
                    VStack {
                        RawDataGraphView(
                            dataPoints: motionManager.magneticDataPointsX,
                            lineColor: .red.opacity(0.5),
                            graphTitle: "Magnetic Field X-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.magneticDataPointsY,
                            lineColor: .green.opacity(0.5),
                            graphTitle: "Magnetic Field Y-Axis"
                        )
                        .frame(height: 100)

                        RawDataGraphView(
                            dataPoints: motionManager.magneticDataPointsZ,
                            lineColor: .blue.opacity(0.5),
                            graphTitle: "Magnetic Field Z-Axis"
                        )
                        .frame(height: 100)
                    }
                } else {
                    Text("No data")
                        .padding(.bottom, 300)
                        .font(.title3)
                        .foregroundStyle(Color.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            Spacer()
            
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
            
            HStack(alignment: .bottom) {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { _, newValue in
                        isRecording = false
                        motionManager.stopRawDataAllCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        // Reset accelerometer data
                        motionManager.userAccelerometerData = []
                        motionManager.rotationalData = []
                        motionManager.magneticFieldData = []
                        motionManager.accelerometerDataPointsX = []
                        motionManager.accelerometerDataPointsY = []
                        motionManager.accelerometerDataPointsZ = []
                        motionManager.rotationalDataPointsX = []
                        motionManager.rotationalDataPointsY = []
                        motionManager.rotationalDataPointsZ = []
                        motionManager.magneticDataPointsX = []
                        motionManager.magneticDataPointsY = []
                        motionManager.magneticDataPointsZ = []
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        motionManager.stopRawDataAllCollection()
                        motionManager.savedFilePath = nil // Reset "File saved" text
                        
                        // Reset accelerometer data
                        motionManager.userAccelerometerData = []
                        motionManager.rotationalData = []
                        motionManager.magneticFieldData = []
                        motionManager.accelerometerDataPointsX = []
                        motionManager.accelerometerDataPointsY = []
                        motionManager.accelerometerDataPointsZ = []
                        motionManager.rotationalDataPointsX = []
                        motionManager.rotationalDataPointsY = []
                        motionManager.rotationalDataPointsZ = []
                        motionManager.magneticDataPointsX = []
                        motionManager.magneticDataPointsY = []
                        motionManager.magneticDataPointsZ = []
                        
                        if newValue {
                            isRecordingRealTime = false
                        }
                    }
            }
            .padding(.horizontal)
            
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
                                .background(isRecording ? Color.blue : Color.gray)
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
                                .padding()
                        }
                    }
                }
                
                HStack(alignment: .bottom) {
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
                                .background(isRecording ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        if motionManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color.primary)
                                .padding()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Raw Data All")
        .onDisappear {
                    // Ensure the recording stops and resources are released when the view disappears
                    if isRecording || isRecordingRealTime || isRecordingInterval {
                        motionManager.stopRawDataAllCollection()
                        isRecording = false
                        isRecordingRealTime = false
                        isRecordingInterval = false
                        motionManager.resetData()
                    }
                }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Data Information")
                            .font(.largeTitle)
                        Text("SAMPLING RATE CONTROL can only be accessed by authorized personal")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.primary)
                        Text("REAL-TIME record the data immediately and stop on-demand")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.primary)
                        Text("TIME-INTERVAL record the data automatically. Set the start and end date, turn on the Start timed recording, and the recording will stop automatically after the end time is up")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.primary)
                        Text("DATA COLLECTION WILL STOP IF THE RAW DATA ALL VIEW IS CLOSED. but you may lock the phone or use another app, and the data collection will still be running")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 5)
                            .foregroundStyle(Color.pink)
                        Spacer()
                        // Adding a chevron as a swipe indicator
                        AnimatedSwipeDownCloseView()
                    }
                    .padding()
                }
            }
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
    var graphTitle: String
    
    var body: some View {
        VStack {
            Text(graphTitle)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .padding(.bottom, 5)
            
            GeometryReader { geometry in
                Path { path in
                    guard dataPoints.count > 1 else { return }
                    
                    let width = geometry.size.width
                    let height = geometry.size.height
                    
                    // Ensure there's a minimum value for scaling in case all data points are zero
                    let maxValue = dataPoints.max() ?? 0
                    let minValue = dataPoints.min() ?? 0
                    _ = maxValue - minValue
                    
                    // Handle case where all values are zero or the same
                    let adjustedMax = max(maxValue, 0.1) // Ensure there's a minimum range
                    let scaleX = width / CGFloat(dataPoints.count - 1)
                    let scaleY = height / CGFloat(adjustedMax - minValue)
                    
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
}

#Preview {
    rawDataAllView()
}
