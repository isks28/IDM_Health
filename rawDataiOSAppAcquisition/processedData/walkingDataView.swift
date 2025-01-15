//
//  processedDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.10.24.
//

import SwiftUI

struct processedDataView: View {
    @State private var selectedView: String? = nil
    @State private var showingInfo = false
    
    init() {
            let appearance = UINavigationBarAppearance()
        
        appearance.titleTextAttributes = [.foregroundColor: UIColor.secondarySystemFill]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
    
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
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Step Counts")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                        .tag("StepCounts")
                HStack{
                    Image(systemName: "6.lane")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Six Minute Walk Test")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                }
                        .tag("SixMinuteWalkTest")
            }
            .navigationTitle("Walking Tests")
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
                            Text("Information")
                                .font(.largeTitle)
                            Text("Step Counts uses pedometer from Core Motion to record the user's steps, distance walked, and cadence")
                                .font(.body)
                                .padding()
                                .padding()
                                .foregroundStyle(Color.primary)
                            Text("Six-minute walk test is a dedicated test to collect Six-Minute-Walk data with a touch of a button. Collected data include: step count, distance, cadence.")
                                .font(.body)
                                .padding()
                                .padding()
                                .foregroundStyle(Color.primary)
                            Spacer()
                            
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
