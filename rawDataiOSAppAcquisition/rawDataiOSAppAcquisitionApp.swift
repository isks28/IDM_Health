//
//  rawDataiOSAppAcquisitionApp.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

@main
struct rawDataiOSAppAcquisitionApp: App {
    
    // Connect AppDelegate to SwiftUI life cycle
        @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
