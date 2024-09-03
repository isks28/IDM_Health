//
//  ContentView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct ContentView: View {
    @State var selectedTab = "Home"
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            healthKitView()
                .tag("HealthKit")
                .tabItem{
                    Image(systemName: "figure.walk")
                    Text("HealthKit")
                }
            
            rawDataView()
                .tag("CoreMotion")
                .tabItem{
                    Image(systemName: "gyroscope")
                    Text("Raw Data")
                }
            
            cameraBasedView()
                .tag("AVFoundation")
                .tabItem{
                    Image(systemName: "camera.fill")
                    Text("Photo and Video")
                }
        }
    }
}

#Preview {
    ContentView()
}
