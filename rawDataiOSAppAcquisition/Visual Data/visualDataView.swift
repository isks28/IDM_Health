//
//  visualDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 08.12.24.
//

import SwiftUI

struct visualDataView: View {
    @State private var selectedView: String? = nil
    @State private var showingInfo = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                HStack {
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Raw Visual Data")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                        }
                        .tag("Raw Visual Data")
                HStack {
                    Image(systemName: "person.and.background.dotted")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Markerless Motion Analysis")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                        }
                        .tag("Markerless Motion Data")
            }
            .navigationTitle("Raw Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("Raw Data information")
                                .font(.largeTitle)
                                .padding()
                            Text("Raw Data fetch unfiletered and filtered (Device Motion) data")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("ACCELEROMETER: measures UNFILTERED acceleration of body in different directions")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("GYROSCOPE: measures UNFILTERED rotation or orientation of body around its axes")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("MAGNETOMETER: measures UNFILTERED magnetic field of body to detect direction like digital compass")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Text("DEVICE MOTION: Device motion measures an iPhone's FILTERED data. User acceleration, rotation rate, gravity acceleration, attitude, and magnetic field using data from the accelerometer, gyroscope, and magnetometer. ")
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
            if selectedView == "Raw Visual Data" {
                cameraBasedView()
            } else if selectedView == "Markerless Motion Data" {
                markerlessMotionAnalysis()
            }  else {
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    visualDataView()
}
