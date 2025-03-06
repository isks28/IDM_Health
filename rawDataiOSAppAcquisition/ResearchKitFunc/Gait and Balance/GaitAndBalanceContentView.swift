//
//  GaitAndBalanceContentView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 24.02.25.
//

import SwiftUI

struct GaitAndBalanceContentView: View {
    @State private var showingInfo = false
    
    var body: some View {
        List {
            NavigationLink(destination: GaitAndBalanceView(taskType: .walkBackAndForth)) {
                HStack {
                    Text("Back and forth walk")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: GaitAndBalanceView(taskType: .short)) {
                HStack {
                    Text("Short walk")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: GaitAndBalanceView(taskType: .gait)) {
                HStack {
                    Text("Timed Walk")
                        .font(.title2)
                    Spacer()
                }
            }
            
            NavigationLink(destination: GaitAndBalanceView(taskType: .balance)) {
                HStack {
                    Text("Six minute walk test")
                        .font(.title2)
                    Spacer()
                }
            }
        }
        .navigationTitle("Gait and Balance")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingInfo.toggle() }) {
                    Image(systemName: "info.circle")
                }
                .sheet(isPresented: $showingInfo) {
                    VStack {
                        Text("Gait and Balance Information")
                            .font(.largeTitle)
                            .padding()
                        Text("This section allows users to assess their gait and balance using ResearchKit tasks.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }
}
