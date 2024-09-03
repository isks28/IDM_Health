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
        
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]  // Title color
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemMint]  // Large title color
            
            UINavigationBar.appearance().standardAppearance = appearance
        
        }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                HStack {
                    Image(systemName: "figure.walk")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.pink)
                    Text("Activity Data")
                        .foregroundStyle(Color.gray)
                        .font(.title)
                        }
                        .tag("Activity")
                HStack{
                    Image(systemName: "shoeprints.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.pink)
                    Text("Mobility Data")
                        .foregroundStyle(Color.gray)
                        .font(.title)
                }
                        .tag("Mobility")
        
            }
            .navigationTitle("HealthKit Data")
        } detail: {
            if selectedView == "Activity" {
                activityView()
            } else if selectedView == "Mobility" {
                mobilityView()
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
