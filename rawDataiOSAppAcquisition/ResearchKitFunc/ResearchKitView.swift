//
//  ResearchKitView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 18.02.25.
//

import SwiftUI

struct ResearchKitView: View {
    @State private var path: [String] = []
    @State private var showingInfo = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: "Range of motion") {
                    HStack {
                        Image(systemName: "figure.arms.open")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Range of motion")
                            .font(.title2)
                        Spacer()
                    }
                }
                
                NavigationLink(value: "Gait and balance") {
                    HStack {
                        Image(systemName: "figure.walk")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Gait and balance")
                            .font(.title2)
                        Spacer()
                    }
                }
            }
            .navigationTitle("ResearchKit")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("ResearchKit Information")
                                .font(.largeTitle)
                                .padding()
                            Text("ResearchKit is an open-source framework by Apple that helps researchers create iOS apps for medical studies.")
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
                case "Range of motion":
                    RangeOfMotionContentView()
                case "Gait and balance":
                    GaitAndBalanceContentView()
                default:
                    Text("Unknown View: \(selectedView)")
                }
            }
        }
    }
}
