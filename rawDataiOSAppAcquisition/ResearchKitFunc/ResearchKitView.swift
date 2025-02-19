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
                            Text(".....")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                            // Replace with your custom close view or button
                            Button("Close") {
                                showingInfo = false
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationDestination(for: String.self) { selectedView in
                switch selectedView {
                case "Range of motion":
                    RangeOfMotionContentView()
                default:
                    Text("Unknown View: \(selectedView)")
                }
            }
        }
    }
}
