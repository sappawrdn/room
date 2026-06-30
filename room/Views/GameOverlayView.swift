//
//  GameOverlayView.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//


import SwiftUI

struct GameOverlayView: View {
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let insanity: Float
    @Binding var moveInput: SIMD2<Float>

    var body: some View {
        ZStack {
            VHSOverlay()
                .frame(width: frameWidth, height: frameHeight)
                .clipped()

            // Vignette Gelap
            RadialGradient(
                colors: [.clear, .black.opacity(0.55)],
                center: .center,
                startRadius: 80,
                endRadius: 480
            )
            .frame(width: frameWidth, height: frameHeight)
            .clipped()
            .allowsHitTesting(false)
            .blendMode(.multiply)

            // Insanity Text
            VStack {
                Text("INSANITY \(Int(insanity * 100))%")
                    .font(.caption.monospaced())
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 10)
                Spacer()
            }

            // Joystick
            VStack {
                Spacer()
                HStack {
                    JoystickView(value: $moveInput)
                        .padding(.leading, 40)
                        .padding(.bottom, 30)
                    Spacer()
                }
            }
        }
    }
}
