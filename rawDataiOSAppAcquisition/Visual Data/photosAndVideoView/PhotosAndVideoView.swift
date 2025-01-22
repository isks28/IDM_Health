//
//  PhotosAndVideoView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 16.01.25.
//

import SwiftUI
import AVFoundation

struct PhotosAndVideoView: View {
    @StateObject private var manager = PhotosAndVideoManager()
    
    var body: some View {
        ZStack {
            CameraPreview(manager: manager)
                .edgesIgnoringSafeArea(.top)
            
            VStack {
                Spacer()
                
                HStack {
                    Button(action: {
                        manager.capturePhoto()
                    }) {
                        ZStack {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if manager.isRecording {
                            manager.stopRecording()
                        } else {
                            manager.startRecording()
                        }
                    }) {
                        ZStack {
                            Image(systemName: "video.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(manager.isRecording ? .pink : .blue)
                        }
                    }
                }
                .padding(.horizontal, 100)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            manager.startSession()
        }
        .onDisappear {
            manager.stopSession()
        }
        .navigationTitle("Photo and Video")
    }
}
