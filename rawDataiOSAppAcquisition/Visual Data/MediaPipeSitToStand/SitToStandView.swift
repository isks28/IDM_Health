//
//  ContentView.swift
//  idmanalysis
//
//  Created by Prashast Singh on 25.02.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct SitToStandView: View {
    @State private var showingVideoPicker = false
    @State private var videoURL: URL?
    @State private var analysisResult: AnalysisResult?
    @State private var isUploading = false
    
    // New: State for showing instructions alert
    @State private var showInstructionsAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Display analysis results if available
                if let result = analysisResult {
                    Text("Squats Count: \(result.numSquats + 1)")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack {
                            ForEach(result.plots.keys.sorted(), id: \.self) { key in
                                if let image = result.plots[key] {
                                    NavigationLink(destination: ZoomableImageView(image: image)) {
                                        VStack {
                                            Text(key)
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 200, height: 150)
                                                .cornerRadius(8)
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("Select a video to analyze your squats.")
                        .foregroundColor(.secondary)
                }
                
                // Button to choose video
                Button(action: {
                    // Show instructions first
                    showInstructionsAlert = true
                }) {
                    Text("Select Video")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .alert("Video Recording Tips", isPresented: $showInstructionsAlert) {
                    Button("OK") {
                        // Once user taps OK, present the video picker
                        showingVideoPicker = true
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("• Test should be performed for 30 seconds.\n• Ensure good lighting.\n• Keep the camera steady.\n• The subject should be clearly visible from head to toe.\n• Record from a 45° angle on the left side so the right knee and inner thigh are visible.")
                }
                
                // Show uploading indicator if needed
                if isUploading {
                    ProgressView("Uploading...")
                }
            }
            .padding()
            .navigationTitle("SIT TO STAND")
            .sheet(isPresented: $showingVideoPicker) {
                VideoPicker(videoURL: $videoURL)
            }
            .onChange(of: videoURL) { _, newURL in
                if let url = newURL {
                    uploadVideo(url: url)
                }
            }
        }
    }
    
    func uploadVideo(url: URL) {
        isUploading = true
        guard let requestURL = URL(string: "https://idmhealthfastdeploy-bnb3dpc2fkc3a5ap.germanywestcentral-01.azurewebsites.net/analyze") else {
            print("Invalid server URL")
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        
        // Create boundary and set header for multipart/form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build the multipart body
        var body = Data()
        let filename = url.lastPathComponent
        let mimeType = "video/mp4"
        
        if let videoData = try? Data(contentsOf: url) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(videoData)
            body.append("\r\n".data(using: .utf8)!)
        } else {
            print("Failed to load video data")
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        // Perform the upload with URLSession
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isUploading = false
            }
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("No data received")
                return
            }
            // Debug: Print raw response
            if let rawString = String(data: data, encoding: .utf8) {
                print("Raw response: \(rawString)")
            }
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(AnalysisResult.self, from: data)
                DispatchQueue.main.async {
                    analysisResult = result
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct AnalysisResult: Codable {
    let numSquats: Int
    let plots_base64: [String: String]
    
    // Map JSON keys to Swift properties
    enum CodingKeys: String, CodingKey {
        case numSquats = "num_squats"
        case plots_base64
    }
    
    // Convert base64 strings into UIImage objects
    var plots: [String: UIImage] {
        var images = [String: UIImage]()
        for (key, base64String) in plots_base64 {
            if let data = Data(base64Encoded: base64String),
               let image = UIImage(data: data) {
                images[key] = image
            }
        }
        return images
    }
}

// ZoomableImageView allows you to view an image in full screen with pinch-to-zoom
struct ZoomableImageView: View {
    let image: UIImage
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.vertical, .horizontal], showsIndicators: false) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                    )
                    .gesture(DragGesture()
                        .onChanged { value in
                            offset = CGSize(width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height)
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                    )
                    .frame(width: geometry.size.width)
            }
            .navigationTitle("Detail View")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// VideoPicker using UIViewControllerRepresentable to bridge UIKit
struct VideoPicker: UIViewControllerRepresentable {
    @Binding var videoURL: URL?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        // Use UTType.movie identifier for video media type
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // No update needed
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let url = info[.mediaURL] as? URL {
                parent.videoURL = url
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ContentView()
}

