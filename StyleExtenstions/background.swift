//
//  background.swift
//  MotionAnalysis
//
//  Created by Prashast Singh on 05.11.24.
//
import SwiftUI

struct WhiteBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .foregroundColor(Color .black)
            .ignoresSafeArea() // Ensures the background fills the entire screen
    }
}

extension View {
    func whiteBackground() -> some View {
        self.modifier(WhiteBackgroundModifier())
    }
}

