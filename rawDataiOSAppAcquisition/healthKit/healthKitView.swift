//
//  healthKitView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct healthKitView: View {
    @State private var path: [String] = []
    @State private var showingInfo = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: "Activity") {
                    HStack {
                        Image(systemName: "figure.walk")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Activity Data")
                            .font(.title2)
                        Spacer()
                    }
                }

                NavigationLink(value: "Mobility") {
                    HStack {
                        Image(systemName: "shoeprints.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Mobility Data")
                            .font(.title2)
                        Spacer()
                    }
                }

                NavigationLink(value: "Vital") {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Health Data")
                            .font(.title2)
                        Spacer()
                    }
                }
            }
            .navigationTitle("HealthKit Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInfo.toggle() }) {
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
            .navigationDestination(for: String.self) { selectedView in
                switch selectedView {
                case "Activity":
                    activityView()
                        .navigationTitle("Activity Data")
                case "Mobility":
                    mobilityView()
                        .navigationTitle("Mobility Data")
                case "Vital":
                    vitalView()
                        .navigationTitle("Health Data")
                default:
                    Text("Unknown View")
                }
            }
        }
    }
}

#Preview {
    healthKitView()
}

