//
//  TensorflowMotionAnalysis.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 04.02.25.
//

import SwiftUI

struct TensorflowMotionAnalysisView: View {
    @State private var showingInfo = false

    var body: some View {
        List {
            NavigationLink("Shoulder Analysis", value: "Shoulder Analysis")
        }
        .navigationTitle("Tensorflow Motion Analysis")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingInfo.toggle() }) {
                    Image(systemName: "info.circle")
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Tensorflow Motion Analysis")
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
            case "Shoulder Analysis":
                TMAShoulderView()
            default:
                Text("Unknown View: \(selectedView)")
            }
        }
    }
}
