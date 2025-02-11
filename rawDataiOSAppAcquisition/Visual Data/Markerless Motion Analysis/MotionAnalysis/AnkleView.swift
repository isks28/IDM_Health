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
            .font(.title2)
            .frame(width: 350, height: 80)
            .background(Color.white)
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 5)
        )
            
            
        }
        .padding()
    }
}
