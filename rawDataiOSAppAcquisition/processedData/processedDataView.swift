//
//  processedDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.10.24.
//

import SwiftUI

struct processedDataView: View {
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
                HStack{
                    Image(systemName: "shoeprints.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Step Counts")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                        .tag("StepCounts")
                HStack{
                    Image(systemName: "6.lane")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Six Minute Walk Test")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                        .tag("SixMinuteWalkTest")
            }
            .navigationTitle("Walking Data")
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
                            Text("Walking data Information")
                                .font(.largeTitle)
                            Text("STEP COUNTS use core motion pedometer to record the user steps, distance,  Floor Counts, Pace and Cadence")
                                .font(.body)
                                .padding()
                                .padding()
                                .foregroundStyle(Color.primary)
                            Text("SIX MINUTE WALK TEST is a dedicated test to collect users Six-Minute-Walk data with a touch of an integrated button")
                                .font(.body)
                                .padding()
                                .padding()
                                .foregroundStyle(Color.primary)
                            Spacer()
                            // Adding a chevron as a swipe indicator
                            AnimatedSwipeDownCloseView()
                        }
                        .padding()
                    }
                }
            }
        } detail: {
            if selectedView == "StepCounts" {
                StepCountView()
            } else if selectedView == "SixMinuteWalkTest" {
                SixMinuteWalkTestView()
            } else {
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    processedDataView()
}
