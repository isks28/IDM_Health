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
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.label
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                
                healthKitView()
                    .tag("HealthKit")
                    .tabItem{
                        Image(systemName: "figure.walk")
                        Text("HealthKit Data")
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
                        Image(systemName: "shoeprints.fill")
                        Text("Walking Data")
                    }
                
                visualDataView()
                    .tag("AVFoundation")
                    .tabItem{
                        Image(systemName: "camera.fill")
                        Text("Visual Data")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
