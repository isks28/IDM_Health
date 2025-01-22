//
//  visualDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 08.12.24.
//

import SwiftUI

struct visualDataView: View {
    @State private var selectedView: String? = nil
    @State private var showingInfo = false
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                HStack {
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Photo and Video")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                        }
                        .tag("Raw Visual Data")
                HStack {
                    Image(systemName: "camera.shutter.button.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Photo and Video test new")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                        }
                        .tag("Photo and Video Data")
                HStack {
                    Image(systemName: "person.and.background.dotted")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .foregroundStyle(Color.blue)
                    Text("Motion Analysis")
                        .foregroundStyle(Color.primary)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(Color.primary)
                        }
                        .tag("Markerless Motion Data")
            }
            .navigationTitle("Visual Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("Visual data information")
                                .font(.largeTitle)
                                .padding()
                            Text("Visual data collects either unprocessed or processed photo or video.")
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
            if selectedView == "Raw Visual Data" {
                cameraBasedView()
            } else if selectedView == "Markerless Motion Data" {
                markerlessMotionAnalysis()
            } else if selectedView == "Photo and Video Data" {
                PhotosAndVideoView()
            } else {
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    visualDataView()
}
