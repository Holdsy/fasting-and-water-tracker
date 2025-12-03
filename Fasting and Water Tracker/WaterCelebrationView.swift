//
//  WaterCelebrationView.swift
//  Fasting and Water Tracker
//
//  Created by AI Assistant on 03/12/2025.
//

import SwiftUI

struct WaterCelebrationView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Dimmed background
            LinearGradient(
                colors: [.black.opacity(0.9), .blue.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Simple "fireworks" bursts
            ZStack {
                FireworkBurstView(delay: 0.0, color: .cyan,  offset: CGSize(width: -120, height: -200))
                FireworkBurstView(delay: 0.2, color: .pink,  offset: CGSize(width: 100, height: -150))
                FireworkBurstView(delay: 0.4, color: .yellow, offset: CGSize(width: -80, height: 40))
                FireworkBurstView(delay: 0.6, color: .mint,  offset: CGSize(width: 130, height: 80))
                FireworkBurstView(delay: 0.8, color: .orange, offset: CGSize(width: 0, height: -40))
            }
            
            VStack(spacing: 20) {
                Text("Congratulations!")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("You have met your daily water goal.")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)
                    .padding(.top, 8)
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(28)
            .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 10)
            .padding(.horizontal, 24)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.4), value: isPresented)
    }
}

private struct FireworkBurstView: View {
    let delay: Double
    let color: Color
    let offset: CGSize
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                let baseAngle = Double(index) / 10.0 * 2.0 * Double.pi
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [color, .white]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 8
                        )
                    )
                    .frame(width: 10, height: 10)
                    .scaleEffect(animate ? 0.1 : 1.0)
                    .offset(
                        x: animate ? cos(baseAngle) * 90 : 0,
                        y: animate ? sin(baseAngle) * 90 : 0
                    )
                    .opacity(animate ? 0 : 1)
                    .animation(
                        Animation.easeOut(duration: 1.2)
                            .repeatForever(autoreverses: false)
                            .delay(delay),
                        value: animate
                    )
            }
        }
        .offset(offset)
        .onAppear {
            animate = true
        }
    }
}


