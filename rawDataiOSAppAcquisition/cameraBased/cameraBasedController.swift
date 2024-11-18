//
//  cameraBasedController.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI
import AVFoundation

struct CameraBasedController: UIViewControllerRepresentable {
    class Coordinator: NSObject {
        var parent: CameraBasedController
        
        init(parent: CameraBasedController) {
            self.parent = parent
        }
    }
    
    var onPhotoCaptured: ((UIImage) -> Void)?
    var onVideoRecorded: ((URL) -> Void)?
    
    @Binding var isRecording: Bool
    @Binding var shouldTakePhoto: Bool
    @Binding var useFrontCamera: Bool
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> CameraBasedManager {
        let cameraViewController = CameraBasedManager()
        cameraViewController.onPhotoCaptured = onPhotoCaptured
        cameraViewController.onVideoRecorded = onVideoRecorded
        cameraViewController.useFrontCamera = useFrontCamera
        return cameraViewController
    }
    
    func updateUIViewController(_ uiViewController: CameraBasedManager, context: Context) {
        if isRecording {
            uiViewController.startRecording()
        } else {
            uiViewController.stopRecording()
        }
        
        if shouldTakePhoto {
            uiViewController.takePhoto()
            DispatchQueue.main.async {
                self.shouldTakePhoto = false
            }
        }
        
        uiViewController.useFrontCamera = useFrontCamera
        uiViewController.updateCameraPosition()
    }
}
