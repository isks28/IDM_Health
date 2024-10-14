//
//  rawDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct rawDataView: View {
    @State private var selectedView: String? = nil
    @State private var showingInfo = false // State to show the info sheet
    
    init() {
            // Customize navigation bar appearance
            let appearance = UINavigationBarAppearance()
        
        appearance.titleTextAttributes = [.foregroundColor: UIColor.secondarySystemFill]  // Title color
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]  // Large title color
    
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                HStack {
                    Image(systemName: "pedal.accelerator.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Accelerometer Data")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                        }
                        .tag("Accelerometer Data")
                HStack {
                    Image(systemName: "gyroscope")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Gyroscope Data")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                        }
                        .tag("Gyroscope Data")
                HStack {
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Magnetometer Data")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                        }
                        .tag("Magnetometer Data")
                HStack{
                    Image(systemName: "chart.pie.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Raw Data All")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                }
                        .tag("RawDataAll")
        
            }
            .navigationTitle("Raw Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfo.toggle() // Show the info sheet when button is tapped
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("Raw Data information")
                                .font(.largeTitle)
                                .padding()
                            Text("Raw Data fetch unprocessed health related data.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("Accelerometer: measures acceleration of body in different directions")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("Gyroscope: measures rotation or orientation of body around its axes")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("Magnetometer: measures magnetic field of body to detect direction like digital compass")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("Raw Data All: measures accelerometer, gyroscope and magnetometer all at the same time")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
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
