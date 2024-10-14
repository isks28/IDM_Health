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
    var onSaveAndUpload: (UIImage?, URL?) -> Void  // New callback for saving and uploading
    
    var body: some View {
        ZStack {
            Color(UIColor.black).edgesIgnoringSafeArea(.all)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let videoURL = videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .background(Color(UIColor.systemBackground))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        AVPlayer(url: videoURL).play()
                    }
            }
            
            VStack {
                Text("Preview screen")
                    .font(.largeTitle)
                    .foregroundStyle(Color.white)
                    .padding(.top, 100)
                Spacer()
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
                                    .stroke(Color.red, lineWidth: 2)
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
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 116) // Adjust padding as needed for UI
            }
        }
    }
}

#Preview {
    PreviewView(image: nil, videoURL: nil, onDismiss: {}, onSaveAndUpload: { _, _ in })
}
