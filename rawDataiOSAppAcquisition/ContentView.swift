//
//  ContentView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct ContentView: View {
    @State var selectedTab = "Home"
    
    init() {
            // Set the appearance of the tab bar globally
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground // Set the background color if needed
            
            // Set the normal and selected item colors
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.black // Unselected icon color
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.black] // Unselected text color
            
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue // Selected icon color
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue] // Selected text color
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance // Ensure the same appearance for edge scrolling
        }
    
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
