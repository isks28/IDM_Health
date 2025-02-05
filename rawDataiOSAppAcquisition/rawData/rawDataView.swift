//
//  rawDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct rawDataView: View {
    @State private var path: [String] = []
    @State private var showingInfo = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: "Accelerometer Data") {
                    HStack {
                        Image(systemName: "pedal.accelerator.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Accelerometer")
                            .font(.title2)
                        Spacer()
                    }
                }

                NavigationLink(value: "Gyroscope Data") {
                    HStack {
                        Image(systemName: "gyroscope")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Gyroscope")
                            .font(.title2)
                        Spacer()
                    }
                }

                NavigationLink(value: "Magnetometer Data") {
                    HStack {
                        Image(systemName: "plusminus.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Magnetometer")
                            .font(.title2)
                        Spacer()
                    }
                }

                NavigationLink(value: "RawData") {
                    HStack {
                        Image(systemName: "move.3d")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("IMU Data")
                            .font(.title2)
                        Spacer()
                    }
                }

                NavigationLink(value: "RawDataAll") {
                    HStack {
                        Image(systemName: "iphone.motion")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Device Motion")
                            .font(.title2)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Sensor Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("IMU Data Information")
                                .font(.largeTitle)
                                .padding()
                            Text("IMU data measures the unfiltered, raw data of accelerometer, gyroscope, and magnetometer simultaneously.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("Accelerometer: measures the unfiltered, linear acceleration of the device in its local axes (x, y, z).")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("Gyroscope: measures the unfiltered rotation rate of the device around its local axes (x, y, z).")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("Magnetometer: measures the unfiltered strength and direction of magnetic fields of the device in its local axes (x, y, z).")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("Device Motion: measures the device's filtered data of linear acceleration, rotation rate, gravity acceleration, attitude, and magnetic field using data from the accelerometer, gyroscope, and magnetometer where the gravitational force is automatically accounted for.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                            AnimatedSwipeDownCloseView()
                        }
                        .padding()
                    }
                }
            }
            .navigationDestination(for: String.self) { selectedView in
                switch selectedView {
                case "Accelerometer Data":
                    accelerometerDataView()
                        .navigationTitle("Accelerometer Data")
                case "Gyroscope Data":
                    gyroscopeDataView()
                        .navigationTitle("Gyroscope Data")
                case "Magnetometer Data":
                    magnetometerDataView()
                        .navigationTitle("Magnetometer Data")
                case "RawData":
                    rawDataAccGyroMagView()
                        .navigationTitle("IMU Data")
                case "RawDataAll":
                    rawDataAllView()
                        .navigationTitle("Device Motion")
                default:
                    Text("Unknown View")
                }
            }
        }
    }
}

#Preview {
    rawDataView()
}
