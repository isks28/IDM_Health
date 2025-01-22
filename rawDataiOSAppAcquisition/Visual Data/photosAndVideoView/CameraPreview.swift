//
//  CameraPreview.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 16.01.25.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let manager: PhotosAndVideoManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = manager.getPreviewLayer()
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PhotosAndVideoView()
    }
}
