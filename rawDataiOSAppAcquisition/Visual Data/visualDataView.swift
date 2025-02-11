//
//  visualDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 08.12.24.
//

import SwiftUI

struct visualDataView: View {
    @State private var path: [String] = []
    @State private var showingInfo = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                NavigationLink(value: "Photo and Video Data") {
                    HStack {
                        Image(systemName: "person.crop.square.badge.camera")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Photo and Video")
                            .font(.title2)
                        Spacer()
                    }
                }
                
                NavigationLink(value: "Vision Finger Motion Analysis") {
                    HStack {
                        Image(systemName: "hand.raised.square")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Vision Finger Motion Analysis")
                            .font(.title2)
                        Spacer()
                    }
                }

                NavigationLink(value: "Markerless Motion Data") {
                    HStack {
                        Image(systemName: "person.and.background.dotted")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .foregroundStyle(Color.blue)
                        Text("Tensorflow Motion Analysis")
                            .font(.title2)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Visual Data")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle")
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("Visual Data Information")
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
            .navigationDestination(for: String.self) { selectedView in
                switch selectedView {
                case "Photo and Video Data":
                    PhotosAndVideoView()
                case "Vision Finger Motion Analysis":
                    CameraView()
                case "Markerless Motion Data":
                    JointView()
                default:
                    Text("Unknown View: \(selectedView)")
                }
            }
        }
    }
}

#Preview {
    visualDataView()
}
