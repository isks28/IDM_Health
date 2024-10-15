//
//  processedDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 11.10.24.
//

import SwiftUI

struct processedDataView: View {
    @State private var selectedView: String? = nil
    @State private var showingInfo = false // State to show the info sheet
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showingInfo) {
                        VStack {
                            Text("Data Information")
                                .font(.largeTitle)
                            Text("Start and End date can only fetch the history or collected data from iOS Health App and not collecting future or unrecorded data.")
                                .font(.body)
                                .padding()
                                .padding()
                                .foregroundStyle(Color.primary)
                        }
                        .padding()
                    }
                }
            }
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
