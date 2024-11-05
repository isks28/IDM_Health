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
    @State private var timeElapsed: Int = 0 // Time elapsed in seconds
    @State private var countdownTimer: Int = 3
    @State private var isCountdownActive = false
    
    @State private var showingInfo = false
    @State private var refreshGraph = UUID()
    
    var body: some View {
        VStack {
            if !isCountdownActive && stepSixMinuteManager.stepCount == 0 {
                Text("Put the phone in the trouser pocket after clicking start")
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
                            
                            // Distance
                            GridRow {
                                Text("Distance:")
                                    .font(.title3)
                                    .gridCellAnchor(.leading)
                                Text(String(format: "%.2f meters", stepSixMinuteManager.distance))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .gridCellAnchor(.trailing)
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
        countdownTimer = 3
        
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
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeElapsed += 1
        }

        Timer.scheduledTimer(withTimeInterval: 360.0, repeats: false) { _ in
            stopTest()
        }
    }

    private func stopTest() {
        stepSixMinuteManager.stopStepCountCollection()
        timer?.invalidate()
        timer = nil
        isRecording = false
    }
}

#Preview {
    SixMinuteWalkTestView()
}
