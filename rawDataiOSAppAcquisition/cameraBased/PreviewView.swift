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
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let videoURL = videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        AVPlayer(url: videoURL).play()
                    }
            }
            
            VStack {
                Text("Preview screen")
                    .font(.largeTitle)
                    .foregroundStyle(Color.primary)
                    .padding(.top, 100)
                Spacer()
                Button(action: onDismiss) {
                    Text("Close")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)  // Font color is black
                        .padding(.vertical, 5)
                        .padding(.horizontal, 15)
                        .background(Color.white)  // Inner background is white
                        .cornerRadius(25)
                        .overlay(  // Adding black outline
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.blue, lineWidth: 2)  // Outline color and width
                        )
                }
                .padding(.bottom, 116) // Adjust padding as needed for UI
            }
        }
    }
}

#Preview {
    PreviewView(image: nil, videoURL: nil, onDismiss: {})
}
