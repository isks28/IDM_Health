//
//  cameraBasedView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import AVKit

struct cameraBasedView: View {
    @State private var isRecording = false
    @State private var showPhoto = false
    @State private var capturedImage: UIImage?
    @State private var capturedVideoURL: URL?
    @State private var shouldTakePhoto = false
    @State private var flashOverlayOpacity = 0.0

    var body: some View {
        ZStack {
            CameraBasedController(
                onPhotoCaptured: { image in
                    capturedImage = image
                    capturedVideoURL = nil
                    showPhoto = true
                    triggerFlash()
                },
                onVideoRecorded: { url in
                    capturedVideoURL = url
                    capturedImage = nil
                    showPhoto = true
                    triggerFlash()
                },
                isRecording: $isRecording,
                shouldTakePhoto: $shouldTakePhoto
            )
            .edgesIgnoringSafeArea(.all)
            
            // Flash overlay
            Color.white
                .opacity(flashOverlayOpacity)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Press the Button to start Recording or Capturing")
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Spacer()
                HStack {
                    Button(action: {
                        isRecording.toggle()
                    }) {
                        Image(systemName: isRecording ? "stop.circle.fill" : "video.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(isRecording ? .pink : .secondary)
                    }
                    .padding(20)
                    
                    Button(action: {
                        shouldTakePhoto = true
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                }
            }
            
            if showPhoto {
                PreviewView(
                    image: capturedImage,
                    videoURL: capturedVideoURL,
                    onDismiss: {
                        showPhoto = false
                    }
                )
                .transition(.move(edge: .bottom))
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
    
    private func triggerFlash() {
        withAnimation(.easeInOut(duration: 0.2)) {
            flashOverlayOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 0.2).delay(0.2)) {
            flashOverlayOpacity = 0.0
        }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

#Preview {
    cameraBasedView()
}
