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
    @State private var timerSelection: Int = 0
    @State private var showTimerOptions = false
    @State private var showingInfo = false
    @State private var countdown = 0
    @State private var isFlashing = false
    @State private var isExpanded = false
    @State private var isPressed = false
    let timerOptions = ["Off", "3s", "5s", "10s"]
    
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
                
                if countdown > 0 {
                    ZStack {
                        Color.black.opacity(0.1)
                            .edgesIgnoringSafeArea(.all)

                        Text("\(countdown)")
                            .font(.system(size: 250, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 25)
                            .transition(.scale)
                    }
                }
                
                VStack {
                    HStack {
                        Spacer()

                        Button(action: {
                            withAnimation(.spring()) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: isExpanded ? 15 : 5) {
                                Image(systemName: "timer")
                                    .foregroundColor(.blue)

                                if isExpanded {
                                    ForEach(0..<timerOptions.count, id: \.self) { index in
                                        Button(action: {
                                            timerSelection = index
                                            withAnimation(.spring()) {
                                                isExpanded = false
                                            }
                                        }) {
                                            Text(timerOptions[index])
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(timerSelection == index ? .white : .blue)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(timerSelection == index ? Color.blue : Color.clear)
                                                .cornerRadius(8)
                                        }
                                    }
                                } else {
                                    Text(timerOptions[timerSelection])
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(30)
                            .frame(height: 50)
                            .shadow(radius: 3)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 20)
                    Spacer()
                    
                    HStack{
                        HStack {
                            Button(action: {
                                if timerSelection > 0 {
                                    countdown = Int(timerOptions[timerSelection].dropLast())!
                                    startCountdown()
                                } else {
                                    manager.capturePhoto()
                                }
                            }) {
                                ZStack {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 60))
                                        .background(Circle().fill(Color.white.opacity(0.95)))
                                        .foregroundColor(.blue)
                                }
                            }
                            Spacer()
                            Button(action: {
                                if manager.isRecording {
                                    manager.stopRecording()
                                } else {
                                    if timerSelection > 0 {
                                        countdown = Int(timerOptions[timerSelection].dropLast())!
                                        startVideoCountdown()
                                    } else {
                                        manager.startRecording()
                                    }
                                }
                            }) {
                                ZStack {
                                    Image(systemName: manager.isRecording ? "stop.circle.fill" : "video.circle.fill")
                                        .font(.system(size: 60))
                                        .background(Circle().fill(Color.white.opacity(0.95)))
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingInfo.toggle()
                }) {
                    Image(systemName: "info.circle")
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Photo and video information")
                            .font(.largeTitle)
                            .padding()
                        Text("Photo and video function take a raw photo or video for further use of either synchronous or asynchronous monitoring")
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
    }
    func startCountdown() {
        if countdown > 0 {
            manager.toggleFlash(on: true)
            isFlashing.toggle()

            withAnimation(.easeInOut(duration: 0.5)) {
                isFlashing.toggle()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                manager.toggleFlash(on: false)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                countdown -= 1
                startCountdown()
            }
        } else {
            manager.capturePhoto()
        }
    }
    func startVideoCountdown() {
        if countdown > 0 {
            manager.toggleFlash(on: true)
            isFlashing.toggle()

            withAnimation(.easeInOut(duration: 0.5)) {
                isFlashing.toggle()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                manager.toggleFlash(on: false)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                countdown -= 1
                startVideoCountdown()
            }
        } else {
            manager.startRecording()
        }
    }
}
