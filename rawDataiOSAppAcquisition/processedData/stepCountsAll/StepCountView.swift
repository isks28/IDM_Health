//
//  StepCountView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.10.24.
//

import SwiftUI
import LocalAuthentication
import CoreMotion
import UserNotifications

struct StepCountView: View {
    @StateObject private var stepManager = StepCountManager()
    @State private var isRecording = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isRecordingRealTime = false
    @State private var isRecordingInterval = false
    @State private var showingAuthenticationError = false
    @State private var canControlStepLength = false
    @State private var timer: Timer? // Timer to update current pace and cadence
    
    @State private var showingInfo = false
    @State private var refreshGraph = UUID()
    
    var body: some View {
        VStack {
            
            if stepManager.stepCount == 0 {
                Text("Put the phone in the pocket after clicking start")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 5)
                    .padding(.horizontal)
            }
            Spacer()
            
            // Step Count Display
            VStack {
                Spacer()
                if !isRecording && stepManager.stepCount == 0{
                VStack {
                    Toggle(isOn: $canControlStepLength) {
                        if stepManager.stepLengthInMeters == 0.7 {
                            Text("Step Length:")
                                .font(.caption2)
                            Text("Default: 0.7 meters")
                                .font(.caption2)
                        } else {
                            Text("Step Length:")
                                .font(.caption2)
                            Text(String(format: "Changed: %.2f meters", stepManager.stepLengthInMeters))
                                .font(.caption2)
                        }
                    }
                    .onChange(of: canControlStepLength) { _, newValue in
                        if newValue {
                            authenticateUser { success in
                                if !success {
                                    canControlStepLength = false
                                    showingAuthenticationError = true
                                } else {
                                    showingAuthenticationError = false
                                }
                            }
                        }
                    }
                }
                .padding()
                
                if canControlStepLength {
                    VStack {
                        Text("Step Length: \(String(format: "%.2f meters", stepManager.stepLengthInMeters))")
                        Slider(value: $stepManager.stepLengthInMeters, in: 0.6...0.8, step: 0.01)
                            .padding([.leading, .trailing], 20)
                    }
                }
            }
                
                if stepManager.stepCount > 0 {
                    Grid {
                        // Step Count
                        VStack {
                            Text("Steps:")
                                .font(.largeTitle)
                                .foregroundStyle(Color.primary)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .gridCellAnchor(.leading)
                            Text("\(stepManager.stepCount)")
                                .font(.largeTitle)
                                .foregroundColor(.primary)
                                .gridCellAnchor(.trailing)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(25)

                        Spacer()
                        
                        // Distance
                        GridRow {
                            Text("Distance GPS:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            Text(String(format: "%.2f meters", stepManager.distanceGPS))
                                .font(.title3)
                                .foregroundColor(.blue)
                                .gridCellAnchor(.trailing)
                        }
                        
                        GridRow {
                            Text("Distance Pedometer:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            Text(String(format: "%.2f meters", stepManager.distancePedometer))
                                .font(.title3)
                                .foregroundColor(.blue)
                                .gridCellAnchor(.trailing)
                        }

                        // Average Active Pace
                        GridRow {
                            Text("Average Active Pace:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            if let averageActivePace = stepManager.averageActivePace {
                                Text(String(format: "%.2f meters/second", averageActivePace))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            } else {
                                Text("Not available")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .gridCellAnchor(.trailing)
                            }
                        }

                        // Current Pace
                        GridRow {
                            Text("Current Pace:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            if let currentPace = stepManager.currentPace {
                                Text(String(format: "%.2f meters/second", currentPace))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            } else {
                                Text("Not available")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .gridCellAnchor(.trailing)
                            }
                        }

                        // Current Cadence
                        GridRow {
                            Text("Current Cadence:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            if let currentCadence = stepManager.currentCadence {
                                Text(String(format: "%.2f steps/second", currentCadence))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            } else {
                                Text("Not available")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .gridCellAnchor(.trailing)
                            }
                        }

                        // Floors Ascended
                        GridRow {
                            Text("Floors Ascended:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            if let floorsAscended = stepManager.floorAscended {
                                Text("\(floorsAscended)")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            } else {
                                Text("Not available")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .gridCellAnchor(.trailing)
                            }
                        }

                        // Floors Descended
                        GridRow {
                            Text("Floors Descended:")
                                .font(.title3)
                                .gridCellAnchor(.leading)
                            if let floorsDescended = stepManager.floorDescended {
                                Text("\(floorsDescended)")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            } else {
                                Text("Not available")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .gridCellAnchor(.trailing)
                            }
                        }
                    }
                } else {
                    Text("Select the Time-Method:")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            
            // Toggle controls for real-time and interval-based recording
            HStack {
                Toggle("Real-Time", isOn: $isRecordingRealTime)
                    .onChange(of: isRecordingRealTime) { _, newValue in
                        isRecording = false
                        stepManager.stopStepCountCollection()
                        stopTimer() // Stop the timer
                        stepManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingInterval = false
                        }
                    }
                
                Toggle("Time-Interval", isOn: $isRecordingInterval)
                    .onChange(of: isRecordingInterval) { _, newValue in
                        isRecording = false
                        stepManager.stopStepCountCollection()
                        stopTimer() // Stop the timer
                        stepManager.savedFilePath = nil // Reset "File saved" text
                        
                        if newValue {
                            isRecordingRealTime = false
                        }
                    }
            }
            .padding(.horizontal)
            
            // Start/Stop buttons for recording
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
                            stepManager.savedFilePath = nil // Reset "File saved" text
                            if newValue {
                                
                                // Define the server URL
                                let serverURL = ServerConfig.serverURL  // Update this URL as needed
                                
                                stepManager.scheduleStepCountCollection(startDate: startDate, endDate: endDate, serverURL: serverURL, baseFolder: "ProcessedStepCountsData") {
                                    DispatchQueue.main.async {
                                        isRecording = false
                                        stopTimer() // Stop the timer
                                        stepManager.removeDataCollectionNotification() // Remove notification
                                    }
                                }
                                stepManager.showDataCollectionNotification() // Show notification on start
                            } else {
                                stepManager.stopStepCountCollection()
                                stopTimer() // Stop the timer
                                stepManager.removeDataCollectionNotification() // Remove notification on stop
                            }
                        }
                        
                        if stepManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color(.blue))
                        }
                    }
                }
                
                HStack {
                    if isRecordingRealTime {
                        Button(action: {
                            stepManager.savedFilePath = nil // Reset "File saved" text when starting a new recording
                            
                            if isRecording {
                                stepManager.stopStepCountCollection()
                                stopTimer() // Stop the timer
                                stepManager.removeDataCollectionNotification() // Remove notification on stop
                                // Define the server URL
                                let serverURL = ServerConfig.serverURL  // Update this URL as needed
                                stepManager.saveDataToCSV(serverURL: serverURL, baseFolder: "ProcessedStepCountsData", recordingMode: "RealTime")
                            } else {
                                let serverURL = ServerConfig.serverURL
                                
                                stepManager.startStepCountCollection(realTime: true, serverURL: serverURL)
                                startTimer() // Start the timer to update current pace and cadence every second
                                stepManager.showDataCollectionNotification() // Show notification on start
                            }
                            isRecording.toggle()
                        }) {
                            Text(isRecording ? "Stop and Save" : "Start")
                                .padding()
                                .background(isRecording ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                        }
                        
                        if stepManager.savedFilePath != nil {
                            Text("File saved")
                                .font(.footnote)
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Step Counts")
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
                        Text("Step Counts Information")
                            .font(.title)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                        ScrollView {
                            Text("The pedometer used for STEP COUNTS measures the number of steps a person takes using data from the accelerometer. It detects repetitive motion patterns typical of walking or running and calculates the total step count accordingly")
                                .font(.callout)
                                .multilineTextAlignment(.leading)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 5)
                                .foregroundStyle(Color.primary)
                            Text("For more information go to: https://developer.apple.com/documentation/coremotion/cmpedometer")
                                .font(.callout)
                                .multilineTextAlignment(.leading)
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
                            Text("Data collection will stop if the step counts view is closed, but it will continue running even if the phone is locked or other apps are in use.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 5)
                                .foregroundStyle(Color.pink)
                                .background(Color.white)
                                .cornerRadius(25)
                                .overlay(  // Adding black outline
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.pink, lineWidth: 2)  // Outline color and width
                                )
                        }
                        .scrollIndicators(.hidden)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                        // Adding a chevron as a swipe indicator
                        AnimatedSwipeDownCloseView()
                    }
                    .padding()
                }
            }
        }
    }
    
    // Start timer to update pace and cadence every second
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            stepManager.updateCurrentPaceAndCadence()
        }
    }
    
    // Stop the timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Function to authenticate the user using Face ID/Touch ID or passcode
    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to start step count recording."
            
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

#Preview {
    StepCountView()
}
