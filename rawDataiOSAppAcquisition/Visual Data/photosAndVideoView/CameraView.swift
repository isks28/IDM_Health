//
//  CameraView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 16.01.25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        VStack {
            CameraPreviewLayer(session: cameraManager.captureSession)
                .edgesIgnoringSafeArea(.all)

            HStack {
                Button(action: {
                    cameraManager.capturePhoto()
                }) {
                    Image(systemName: "camera.circle")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.white)
                }
                .padding()

                Button(action: {
                    if cameraManager.isRecording {
                        cameraManager.stopRecording()
                    } else {
                        cameraManager.startRecording()
                    }
                }) {
                    Image(systemName: cameraManager.isRecording ? "stop.circle" : "video.circle")
                        .resizable()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.red)
                }
                .padding()
            }
        }
        .onAppear {
            cameraManager.setupSession()
        }
    }
}

struct CameraPreviewLayer: UIViewRepresentable {
    var session: AVCaptureSession?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        if let session = session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
