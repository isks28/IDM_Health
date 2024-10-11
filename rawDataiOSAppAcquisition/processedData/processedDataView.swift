//
//  processedDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.10.24.
//

import SwiftUI

struct processedDataView: View {
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
                HStack{
                    Image(systemName: "shoeprints.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.blue)
                    Text("Step Counts")
                        .foregroundStyle(Color.primary)
                        .font(.title)
                }
                        .tag("StepCounts")
            }
            .navigationTitle("Processed Data")
        } detail: {
            if selectedView == "StepCounts" {
                StepCountView()
            } else {
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    processedDataView()
}
