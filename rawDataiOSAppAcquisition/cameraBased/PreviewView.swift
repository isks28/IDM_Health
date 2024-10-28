//
//  PreviewView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 12.10.24.
//

import SwiftUI
import AVKit

struct PreviewView: View {
    var image: UIImage?
    var videoURL: URL?
    var onDismiss: () -> Void
    var onSaveAndUpload: (UIImage?, URL?) -> Void
    
    @State private var player: AVPlayer?  // State to hold the AVPlayer instance
    
    var body: some View {
        ZStack {
        
            VStack {
                
                Text("Preview View")
                    .foregroundColor(.white)
                    .font(.headline)
                
                // Define a consistent frame size
                let frameSize: CGFloat = 390
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: frameSize, height: frameSize) // Apply consistent frame size
                } else if videoURL != nil {
                    if let player = player {
                        VideoPlayer(player: player)
                            .frame(width: frameSize, height: frameSize) // Apply consistent frame size
                            .aspectRatio(contentMode: .fit)
                            .onAppear {
                                player.play()  // Automatically play the video on appear
                            }
                            .onDisappear {
                                player.pause()  // Pause the video when view disappears
                            }
                    }
                }
                
                HStack {
                    // Retake Button
                    Button(action: onDismiss) {
                        Text("Retake")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 15)
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Save and Upload Button
                    Button(action: {
                        onSaveAndUpload(image, videoURL)
                    }) {
                        Text("Save and Upload")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 15)
                            .background(Color.white)
                            .cornerRadius(25)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .onAppear {
            if let videoURL = videoURL {
                player = AVPlayer(url: videoURL)  // Initialize the player once when the view appears
            }
        }
    }
}

#Preview {
    PreviewView(image: nil, videoURL: nil, onDismiss: {}, onSaveAndUpload: { _, _ in })
}
