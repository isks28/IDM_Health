//
//  healthKitView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct healthKitView: View {
    @State private var selectedView: String? = nil
    @State private var showingInfo = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                HStack {
                    Image(systemName: "figure.walk")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Activity")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                .tag("Activity")
                
                HStack {
                    Image(systemName: "shoeprints.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Mobility")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                .tag("Mobility")
                
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Health Data")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                .tag("Vital")
            }
            .navigationTitle("HealthKit Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("HealthKit Information")
                                .font(.largeTitle)
                                .padding()
                            Text("HealthKit can only pull the data available in the Apple Health app. No new data can be recorded.")
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
            if selectedView == "Activity" {
                activityView()
            } else if selectedView == "Mobility" {
                mobilityView()
            } else if selectedView == "Vital" {
                vitalView()
            } else {
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    healthKitView()
}
