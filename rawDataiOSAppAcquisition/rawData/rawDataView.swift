//
//  rawDataView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 03.09.24.
//

import SwiftUI

struct rawDataView: View {
    @State private var selectedView: String? = nil
    
    init() {
            // Customize navigation bar appearance
            let appearance = UINavigationBarAppearance()
        
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]  // Title color
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.systemMint] // Large title color
            
            UINavigationBar.appearance().standardAppearance = appearance
        
        }
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedView) {
                HStack {
                    Image(systemName: "pedal.accelerator.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.pink)
                    Text("Accelerometer Data")
                        .foregroundStyle(Color.gray)
                        .font(.title)
                        }
                        .tag("Accelerometer Data")
                HStack {
                    Image(systemName: "gyroscope")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.pink)
                    Text("Gyroscope Data")
                        .foregroundStyle(Color.gray)
                        .font(.title)
                        }
                        .tag("Gyroscope Data")
                HStack {
                    Image(systemName: "globe")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.pink)
                    Text("Magnetometer Data")
                        .foregroundStyle(Color.gray)
                        .font(.title)
                        }
                        .tag("Magnetometer Data")
                HStack{
                    Image(systemName: "chart.pie.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 50)
                        .foregroundStyle(Color.pink)
                    Text("Raw Data All")
                        .foregroundStyle(Color.gray)
                        .font(.title)
                }
                        .tag("RawDataAll")
        
            }
            .navigationTitle("Raw Data")
        } detail: {
            if selectedView == "Accelerometer Data" {
                accelerometerDataView()
            } else if selectedView == "Gyroscope Data" {
                gyroscopeDataView()
            } else if selectedView == "Magnetometer Data" {
                magnetometerDataView()
            } else if selectedView == "RawDataAll" {
                rawDataAllView()
            } else {
                Text("Select a view")
                    .font(.largeTitle)
            }
        }
    }
}

#Preview {
    rawDataView()
}
