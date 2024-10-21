//
//  warningView.swift
//  rawDataiOSAppAcquisition
//
//  Created by Irnu Suryohadi Kusumo on 21.10.24.
//

import SwiftUI

struct WarningView: View {
    @Binding var isPresented: Bool  // Binding to control when to dismiss the warning
    
    var body: some View {
        
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.2)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Please always read the info screen located on the top-right on every view")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.pink)
                    .padding()
                
                Button(action: {
                    isPresented = false  // Dismiss the warning screen
                }) {
                    Text("Dismiss")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .frame(maxWidth: 300)  // Control the width of the pop-up
                }
            }
        }
