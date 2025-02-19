//
//  RangeOfMotionContentView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 18.02.25.
//

import SwiftUI

struct RangeOfMotionContentView: View {
    @State private var showingInfo = false
    
    var body: some View {
        List {
            NavigationLink(destination: RangeOfMotionView(taskType: .leftShoulder)) {
                HStack {
                    Text("Left shoulder")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: RangeOfMotionView(taskType: .rightShoulder)) {
                HStack {
                    Text("Right shoulder")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: RangeOfMotionView(taskType: .leftKnee)) {
                HStack {
                    Text("Left knee")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: RangeOfMotionView(taskType: .rightKnee)) {
                HStack {
                    Text("Right knee")
                        .font(.title2)
                    Spacer()
                }
            }
        }
        .navigationTitle("Range of Motion")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingInfo.toggle() }) {
                    Image(systemName: "info.circle")
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Range of motion Information")
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
    }
}
