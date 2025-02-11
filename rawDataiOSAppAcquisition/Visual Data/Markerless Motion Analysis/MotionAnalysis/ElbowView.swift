//
//  ElbowView.swift
//  MotionAnalysis
//
//  Created by Prashast Singh on 04.11.24.
//
import SwiftUI
import Foundation

struct ElbowView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("LEFT ELBOW MOVEMENTS")
                .font(.system(size: 30, weight: .bold))
            
            NavigationLink(destination: StoryboardViewWrapper(joint: .elbow , bodySide: .left, recordDirection: .side)) {
                Text("FLEXION EXTENSION")
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
            
            /*      NavigationLink(destination: StoryboardViewWrapper(joint: .elbow, bodySide: .left, recordDirection: .front)) {
                Text("PRONATION SUPINIATION")
                    .font(.system(size: 25, weight: .bold))
                    .frame(width: 300, height: 100)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            */
            Text("RIGHT ELBOW MOVEMENTS")
                .font(.system(size: 30, weight: .bold))
            
            NavigationLink(destination: StoryboardViewWrapper(joint: .elbow, bodySide: .right, recordDirection: .side)) {
                Text("FLEXION EXTENSION")
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
            
          /*  NavigationLink(destination: StoryboardViewWrapper(joint: .elbow, bodySide: .right, recordDirection: .front)) {
                Text("PRONATION SUPINIATION")
                    .font(.system(size: 25, weight: .bold))
                    .frame(width: 300, height: 100)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            */
        }
        .padding()
    }
}

#Preview {
    ElbowView()
}
