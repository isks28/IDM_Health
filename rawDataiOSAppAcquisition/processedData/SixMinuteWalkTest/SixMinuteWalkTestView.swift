//
//  SixMinuteWalkTestView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 31.10.24.
//

import SwiftUI
import LocalAuthentication
import CoreMotion
import UserNotifications

struct SixMinuteWalkTestView: View {
    @StateObject private var stepSixMinuteManager = SixMinuteWalkTestManager()
    @State private var isRecording = false
    @State private var showingAuthenticationError = false
    @State private var timer: Timer?
    @State private var timeElapsed: Int = 0
    @State private var countdownTimer: Int = 3
    @State private var isCountdownActive = false
    @State private var canControlStepLength = false
    @State private var showingInfo = false
    @State private var refreshGraph = UUID()

    var body: some View {
        VStack {
            if !isCountdownActive && stepSixMinuteManager.stepCount == 0 {
                Text("Put the phone in the pants pocket after clicking start")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 5)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            if isCountdownActive {
                Text("Starting in \(countdownTimer)...")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .padding()
            } else {
                Text("Elapsed Time: \(formattedTime)")
                    .font(.title2)
                    .padding(.bottom)
                    .foregroundStyle(Color.primary)
                
                VStack {
                    Spacer()
                    if stepSixMinuteManager.stepCount > 0 {
                        Grid {
                            VStack {
                                Text("Steps:")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.primary)
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 15)
                                    .gridCellAnchor(.leading)
                                Text("\(stepSixMinuteManager.stepCount)")
                                    .font(.largeTitle)
                                    .foregroundColor(.primary)
                                    .gridCellAnchor(.trailing)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(25)
                            
                            Spacer()
                            
                            GridRow {
                                Text("Distance GPS:")
                                    .font(.title3)
                                    .gridCellAnchor(.leading)
                                Text(String(format: "%.2f meters", stepSixMinuteManager.distanceGPS))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            }
                            
                            GridRow {
                                Text("Distance Pedometer:")
                                    .font(.title3)
                                    .gridCellAnchor(.leading)
                                Text(String(format: "%.2f meters", stepSixMinuteManager.distancePedometer))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
                            }
                            
                            GridRow {
                                Text("Average Active Pace:")
                                    .font(.title3)
                                    .gridCellAnchor(.leading)
                                if let averageActivePace = stepSixMinuteManager.averageActivePace {
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
                            
                            GridRow {
                                Text("Current Pace:")
                                    .font(.title3)
                                    .gridCellAnchor(.leading)
                                if let currentPace = stepSixMinuteManager.currentPace {
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
                            
                            GridRow {
                                    Text("Current Cadence:")
                                        .font(.title3)
                                        .gridCellAnchor(.leading)
                                    if let currentCadence = stepSixMinuteManager.currentCadence {
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
                            
                            GridRow {
                                Text("Floors Ascended:")
                                    .font(.title3)
                                    .gridCellAnchor(.leading)
                                if let floorsAscended = stepSixMinuteManager.floorAscended {
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
                            
                            GridRow {
                                Text("Floors Descended:")
                                    .font(.title3)
                                    .gridCellAnchor(.leading)
                                if let floorsDescended = stepSixMinuteManager.floorDescended {
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
                    }
                    
                    // Step Length Control with Authentication
                    if !isRecording && stepSixMinuteManager.stepCount == 0{
                    VStack {
                        Toggle(isOn: $canControlStepLength) {
                            if stepSixMinuteManager.stepLengthInMeters == 0.7 {
                                Text("Step Length:")
                                    .font(.caption2)
                                Text("Default: 0.7 meters")
                                    .font(.caption2)
                            } else {
                                Text("Step Length:")
                                    .font(.caption2)
                                Text(String(format: "Changed: %.2f meters", stepSixMinuteManager.stepLengthInMeters))
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
                            Text("Step Length: \(String(format: "%.2f meters", stepSixMinuteManager.stepLengthInMeters))")
                            Slider(value: $stepSixMinuteManager.stepLengthInMeters, in: 0.6...0.8, step: 0.01)
                                .padding([.leading, .trailing], 20)
                        }
                    }
                }
            }
        }
            Spacer()

            VStack {
                Button(action: {
                    stepSixMinuteManager.savedFilePath = nil

                    if isRecording {
                        stepSixMinuteManager.stopStepCountCollection()
                        stopTest()
                        stepSixMinuteManager.removeDataCollectionNotification()
                    } else {
                        startCountdown()
                    }
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "6-Minute Walk Test is Running" : "Start 6-Minute Walk Test")
                        .padding()
                        .background(isRecording ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }

                if stepSixMinuteManager.savedFilePath != nil {
                    Text("File saved")
                        .font(.footnote)
                        .foregroundStyle(Color.primary)
                }
            }
            .padding()
        }
        .navigationTitle("Six-Minute-Walk Test")
        .onDisappear  {
            if isRecording {
                stopTest()
                stepSixMinuteManager.stopStepCountCollection(saveData: false)
                stepSixMinuteManager.removeDataCollectionNotification()
                isRecording = false
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
                        Text("Step Counts Information")
                            .font(.title)
                            .multilineTextAlignment(.leading)
                            .padding(.top)
                        ScrollView {
                            Text("The pedometer used for STEP COUNTS measures the number of steps a person takes using data from the accelerometer. It detects repetitive motion patterns typical of walking or running and calculates the total step count accordingly.")
                                .font(.callout)
                                .multilineTextAlignment(.leading)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 5)
                                .foregroundStyle(Color.primary)
                            Text("6-Minute Walk Test records the data automatically and stops after six minutes.")
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.pink, lineWidth: 2)
                                )
                        }
                        .scrollIndicators(.hidden)
                        .padding(.horizontal)
                        .padding(.bottom, 5)
                    }
                    .padding()
                }
            }
        }
    }

    private var formattedTime: String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func startCountdown() {
        isCountdownActive = true
        countdownTimer = 5

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownTimer > 1 {
                countdownTimer -= 1
            } else {
                timer.invalidate()
                isCountdownActive = false
                startTest()
            }
        }
    }

    private func startTest() {
        timeElapsed = 0
        stepSixMinuteManager.startStepCountCollection(serverURL: ServerConfig.serverURL)
        
        // Start the timer for updating elapsed time and notification
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeElapsed += 1
            stepSixMinuteManager.showDataCollectionNotification(elapsedTime: timeElapsed)
        }
        
        // Stop test after 6 minutes (360 seconds)
        Timer.scheduledTimer(withTimeInterval: 360.0, repeats: false) { _ in
            stopTest()
        }
    }

    private func stopTest() {
        stepSixMinuteManager.stopStepCountCollection()
        timer?.invalidate()
        timer = nil
        isRecording = false
        
        // Optionally remove the notification once the test stops
        stepSixMinuteManager.removeDataCollectionNotification()
    }

    func authenticateUser(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate to enable step length control."

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
    SixMinuteWalkTestView()
}
