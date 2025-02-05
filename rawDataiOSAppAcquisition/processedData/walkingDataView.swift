//
//  processedDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.10.24.
//

import SwiftUI

struct processedDataView: View {
    @State private var path: [String] = []
    @State private var showingInfo = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: "StepCounts") {
                    HStack {
                        Image(systemName: "shoeprints.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Step Counts")
                            .font(.title2)
                        Spacer()
                    }
                }

                NavigationLink(value: "SixMinuteWalkTest") {
                    HStack {
                        Image(systemName: "6.lane")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Six Minute Walk Test")
                            .font(.title2)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Walking Tests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("Information")
                                .font(.largeTitle)
                            Text("Step Counts uses pedometer from Core Motion to record the user's steps, distance walked, and cadence.")
                                .font(.body)
                                .padding()
                                .foregroundStyle(Color.primary)
                            Text("Six-minute walk test is a dedicated test to collect Six-Minute-Walk data with a touch of a button. Collected data include: step count, distance, cadence.")
                                .font(.body)
                                .padding()
                                .foregroundStyle(Color.primary)
                            Spacer()
                            AnimatedSwipeDownCloseView()
                        }
                        .padding()
                    }
                }
            }
            .navigationDestination(for: String.self) { selectedView in
                switch selectedView {
                case "StepCounts":
                    StepCountView()
                        .navigationTitle("Step Counts")  
                case "SixMinuteWalkTest":
                    SixMinuteWalkTestView()
                        .navigationTitle("Six Minute Walk Test")
                default:
                    Text("Unknown View")
                }
            }
        }
    }
}

#Preview {
    processedDataView()
}
