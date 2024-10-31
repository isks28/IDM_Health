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
    @State private var timer: Timer? // Timer for periodic updates if needed
    
    @State private var countdownTimer: Int = 3
    @State private var isCountdownActive = false
    
    @State private var showingInfo = false
    @State private var refreshGraph = UUID()
    
    var body: some View {
        VStack {
            
            if !isCountdownActive && stepSixMinuteManager.stepCount == 0 {
                Text("Put the phone in the pocket after clicking start")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)
                    .padding(.top, 5)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Countdown Timer
            if isCountdownActive {
                Text("Starting in \(countdownTimer)...")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
                    .padding()
            } else {
                // Step Count Display
                VStack {
                    Spacer()
                    if stepSixMinuteManager.stepCount > 0 {
                        Grid {
                            // Step Count
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
                            
                            // Distance
                            GridRow {
                                Text("Distance:")
                                    .font(.title3)
                                    .gridCellAnchor(.leading)
                                if let distance = stepSixMinuteManager.distance {
                                    Text(String(format: "%.2f meters", distance))
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

                            // Average Active Pace
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

                            // Current Pace
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

                            // Current Cadence
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

                            // Floors Ascended
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

                            // Floors Descended
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
                }
            }
            Spacer()
            
            // Start/Stop button for 6MWT recording
            VStack {
                Button(action: {
                    stepSixMinuteManager.savedFilePath = nil // Reset "File saved" text when starting a new recording
                    
                    if isRecording {
                        stepSixMinuteManager.stopStepCountCollection()
                        stopTimer() // Stop the timer
                        stepSixMinuteManager.removeDataCollectionNotification() // Remove notification on stop
                    } else {
                        startCountdown() // Start the 3-second countdown before starting the test
                    }
                    isRecording.toggle()
                }) {
                    Text(isRecording ? "Stop and Save" : "Start 6-Minute Walk Test")
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
    
    // Start a 3-second countdown before starting data collection
    private func startCountdown() {
        isCountdownActive = true
        countdownTimer = 3
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownTimer > 1 {
                countdownTimer -= 1
            } else {
                timer.invalidate()
                isCountdownActive = false
                stepSixMinuteManager.startStepCountCollection() // Start the 6-minute walk test after countdown
                stepSixMinuteManager.updateCurrentPaceAndCadence() // Start the timer if periodic updates are needed
                stepSixMinuteManager.showDataCollectionNotification() // Show notification on start
            }
        }
    }
    
    // Stop the timer
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    SixMinuteWalkTestView()
}
