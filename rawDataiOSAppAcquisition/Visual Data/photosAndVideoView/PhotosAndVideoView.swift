//
//  PhotosAndVideoView.swift
//  rawDataiOSAppAcquisition
//

import SwiftUI
import AVFoundation

struct PhotosAndVideoView: View {
    @StateObject private var manager = PhotosAndVideoManager()
    @State private var isReviewingPhoto = false
    @State private var isReviewingVideo = false
    @State private var capturedVideoURL: URL? = nil

    var body: some View {
        ZStack {
            if isReviewingPhoto, let image = manager.capturedPhoto {
                VStack {
                    Spacer()
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height * 1)
                        .clipShape(Rectangle())
                        .shadow(radius: 5)
                        .padding()
                    
                    Spacer()

                    HStack {
                        Button(action: {
                            isReviewingPhoto = false
                            manager.startSession()
                        }) {
                            Text("Retake")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .background(Color.white)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                )
                        }

                        Spacer()

                        Button(action: {
                            manager.savePhoto(image)
                            isReviewingPhoto = false
                            manager.startSession()
                        }) {
                            Text("Save and upload")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .background(Color.white)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                )
                        }
                    }
                    .padding()
                }
            } else if isReviewingVideo, let videoURL = capturedVideoURL {
                VStack {
                    VideoPlayerView(videoURL: videoURL)
                        .edgesIgnoringSafeArea(.all)
                    
                    HStack {
                        Button(action: {
                            isReviewingVideo = false
                            manager.startSession()
                        }) {
                            Text("Retake")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .background(Color.white)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            manager.saveVideo(videoURL)
                            isReviewingVideo = false
                            manager.startSession()
                        }) {
                            Text("Save and upload")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 15)
                                .background(Color.white)
                                .cornerRadius(5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                )
                        }
                    }
                    .padding()
                }
            } else {
                CameraPreview(manager: manager)
                    .edgesIgnoringSafeArea(.top)
                
                VStack {
                    Spacer()
                    
                    HStack{
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
                                    Image(systemName: manager.isRecording ? "stop.circle.fill" : "video.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(manager.isRecording ? .pink : .blue)
                                }
                            }
                        }
                        .padding(.horizontal, 50)
                        Button(action: {
                            manager.switchCamera()
                        }) {
                            ZStack {
                                Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                                    .font(.system(size: 25))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            manager.startSession()
        }
        .onDisappear {
            manager.stopSession()
        }
        .onChange(of: manager.capturedPhoto) { _, newPhoto in
            if newPhoto != nil {
                manager.stopSession()
                isReviewingPhoto = true
            }
        }
        .onChange(of: manager.capturedVideoURL) { _, newVideoURL in
            if newVideoURL != nil {
                manager.stopSession()
                capturedVideoURL = newVideoURL
                isReviewingVideo = true
            }
        }
    }
}
