//
//  healthKitView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct healthKitView: View {
    @State private var selectedView: String? = nil
    
    init() {
            // Customize navigation bar appearance
            let appearance = UINavigationBarAppearance()
        
                appearance.titleTextAttributes = [.foregroundColor: UIColor.secondarySystemFill]  // Title color
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]  // Large title color
            
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                HStack {
                    Image(systemName: "figure.walk")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Activity Data")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                        }
                        .tag("Activity")
                HStack{
                    Image(systemName: "shoeprints.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Mobility Data")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                }
                        .tag("Mobility")
                HStack{
                    Image(systemName: "heart.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Vital Data")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                }
                        .tag("Vital")
        
            }
            .navigationTitle("HealthKit Data")
        } detail: {
            if selectedView == "Activity" {
                activityView()
            } else if selectedView == "Mobility" {
                mobilityView()
            } else if selectedView == "Vital" {
                vitalView()
            } else {
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    healthKitView()
}
