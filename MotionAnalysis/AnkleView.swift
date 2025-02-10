//
//  AnkleView.swift
//  MotionAnalysis
//
//  Created by Prashast Singh on 04.11.24.
//
import Foundation
import SwiftUI

struct AnkleView : View {
    var body: some View {
        VStack(spacing: 20) {
            Text("ANKLE MOVEMENTS")
                .font(.system(size: 30, weight: .bold))
            
            Button("DORSI PLANTER FLEXION") {
                // Action for Flexion
            }
            .font(.system(size: 25, weight: .bold))
            .frame(width: 300, height: 100)
            .background(Color.black)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            
        }
        .padding()
    }
}
