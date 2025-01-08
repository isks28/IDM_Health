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
    @State private var useFrontCamera = false
    var serverURL: URL?
    
    @State private var showingInfo = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
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
                    shouldTakePhoto: $shouldTakePhoto,
                    useFrontCamera: $useFrontCamera
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(0)
                .edgesIgnoringSafeArea(.all)
                
                Color.white
                    .opacity(flashOverlayOpacity)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            isRecording.toggle()
                        }) {
                            Image(systemName: isRecording ? "stop.circle.fill" : "video.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(isRecording ? .pink : .blue)
                        }
                        .padding(20)
                        
                        Button(action: {
                            shouldTakePhoto = true
                        }) {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        .padding(20)

                        Button(action: {
                            useFrontCamera.toggle()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
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
                        },
                        onSaveAndUpload: { image, videoURL in
                            saveAndUploadData(image: image, videoURL: videoURL)
                            showPhoto = false
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.92))
                    .edgesIgnoringSafeArea(.all)
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationTitle("Photo and video")
            .padding(.top, -8)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("Photo and video Information")
                                .font(.title)
                                .padding(.top)
                            ScrollView {
                                Text("Photo and video collects visual data from the user's device")
                                    .padding()
                            }
                            .scrollIndicators(.hidden)
                            .padding(.horizontal)
                        }
                        .padding()
                    }
                }
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
    
    private func saveAndUploadData(image: UIImage?, videoURL: URL?) {
        if let image = image {
            savePhotoToDocuments(image, serverURL: ServerConfig.serverURL)
        } else if let videoURL = videoURL {
            saveVideoToDocuments(videoURL, serverURL: ServerConfig.serverURL)
        }
    }
    
    func savePhotoToDocuments(_ image: UIImage, serverURL: URL) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }

        let folderURL = documentsDirectory.appendingPathComponent("Recorded Photo and Video")

        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                print("Created folder: \(folderURL.path)")
            } catch {
                print("Failed to create folder: \(error)")
                return
            }
        }

        let filename = UUID().uuidString + ".jpg"
        let fileURL = folderURL.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 1.0) else { return }

        do {
            try data.write(to: fileURL)
            print("Saved photo to: \(fileURL.path)")
            uploadFile(fileURL: fileURL, serverURL: serverURL, category: "Photo")
        } catch {
            print("Failed to save photo: \(error)")
        }
    }

    func saveVideoToDocuments(_ videoURL: URL, serverURL: URL) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Documents directory not found")
            return
        }

        let folderURL = documentsDirectory.appendingPathComponent("Recorded Photo and Video")

        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                print("Created folder: \(folderURL.path)")
            } catch {
                print("Failed to create folder: \(error)")
                return
            }
        }

        let filename = UUID().uuidString + ".mp4"
        let fileURL = folderURL.appendingPathComponent(filename)

        do {
            try FileManager.default.moveItem(at: videoURL, to: fileURL)
            print("Saved video to: \(fileURL.path)")
            uploadFile(fileURL: fileURL, serverURL: serverURL, category: "Video")
        } catch {
            print("Failed to save video: \(error)")
        }
    }

    func uploadFile(fileURL: URL, serverURL: URL, category: String) {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        let fileName = fileURL.lastPathComponent
        let mimeType: String

        if fileURL.pathExtension == "jpg" {
            mimeType = "image/jpeg"
        } else if fileURL.pathExtension == "mp4" {
            mimeType = "video/mp4"
        } else {
            mimeType = "text/csv"
        }

        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"category\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(category)\r\n".data(using: .utf8)!)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(try! Data(contentsOf: fileURL))
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
            if let error = error {
                print("Error uploading file: \(error)")
                return
            }
            print("File uploaded successfully to server")
        }

        task.resume()
    }
}

#Preview {
    cameraBasedView()
}

