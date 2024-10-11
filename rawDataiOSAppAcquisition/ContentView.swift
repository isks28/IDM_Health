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
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.label // Unselected icon color
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.label] // Unselected text color
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue // Selected icon color
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue] // Selected text color
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance // Ensure the same appearance for edge scrolling
        
        // Set the appearance for the navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground // Adaptive background
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label] // Adaptive text color for title
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            healthKitView()
                .tag("HealthKit")
                .tabItem{
                    Image(systemName: "figure.walk")
                    Text("HealthKit")
                }
                .onAppear {
                    let navAppearance = UINavigationBarAppearance()
                    navAppearance.configureWithOpaqueBackground()
                    navAppearance.backgroundColor = UIColor.systemBackground
                    navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
                    
                    UINavigationBar.appearance().standardAppearance = navAppearance
                    UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
                }
            
            rawDataView()
                .tag("CoreMotion")
                .tabItem{
                    Image(systemName: "gyroscope")
                    Text("Raw Data")
                }
            
            processedDataView()
                .tag("CoreMotionProcessed")
                .tabItem{
                    Image(systemName: "desktopcomputer")
                    Text("Processed Data")
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
