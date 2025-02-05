//
//  TMAShoulderView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 04.02.25.
//

import SwiftUI

struct TMAShoulderView: View {
    @State private var showingInfo = false

    var body: some View {
        List {
            NavigationLink("Left Shoulder", value: "Left Shoulder")
            NavigationLink("Right Shoulder", value: "Right Shoulder")
        }
        .navigationTitle("Shoulder Analysis")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingInfo.toggle() }) {
                    Image(systemName: "info.circle")
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Shoulder Analysis")
                            .font(.largeTitle)
                            .padding()
                        Text("Detailed description goes here.")
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
            case "Left Shoulder":
                LeftShoulderAnalysisView()
            case "Right Shoulder":
                RightShoulderAnalysisView()
            default:
                Text("Unknown View: \(selectedView)")
            }
        }
    }
}
