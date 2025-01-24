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
                    Image(systemName: "person.crop.square.badge.camera")
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
            switch selectedView {
            case "Photo and Video Data":
                PhotosAndVideoView()
            case "Markerless Motion Data":
                markerlessMotionAnalysis()
            default:
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    visualDataView()
}
