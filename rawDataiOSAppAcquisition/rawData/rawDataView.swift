//
//  rawDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct rawDataView: View {
    @State private var selectedView: String? = nil
    @State private var showingInfo = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                HStack {
                    Image(systemName: "pedal.accelerator.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Accelerometer")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                        }
                        .tag("Accelerometer Data")
                HStack {
                    Image(systemName: "gyroscope")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Gyroscope")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                        }
                        .tag("Gyroscope Data")
                HStack {
                    Image(systemName: "plusminus.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Magnetometer")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                        }
                        .tag("Magnetometer Data")
                HStack{
                    Image(systemName: "move.3d")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("IMU Data")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                        .tag("RawData")
                HStack{
                    Image(systemName: "iphone.motion")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Device Motion")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                        .tag("RawDataAll")
        
            }
            .navigationTitle("Sensor Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("IMU data Information")
                                .font(.largeTitle)
                                .padding()
                            Text("IMU data measures the unfiltered, raw data of accelerometer, gyroscope and magnetometer simultaneously.")
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
        } detail: {
            if selectedView == "Accelerometer Data" {
                accelerometerDataView()
            } else if selectedView == "Gyroscope Data" {
                gyroscopeDataView()
            } else if selectedView == "Magnetometer Data" {
                magnetometerDataView()
            } else if selectedView == "RawData" {
                rawDataAccGyroMagView()
            } else if selectedView == "RawDataAll" {
                rawDataAllView()
            }  else {
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    rawDataView()
}
