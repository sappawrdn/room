//
//  JoystickView.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//


import SwiftUI

struct JoystickView: View {
    @Binding var value: SIMD2<Float>
    @State private var knob: CGSize = .zero
    let radius: CGFloat = 55

    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.15))
                .frame(width: radius * 2, height: radius * 2)
            Circle().fill(.white.opacity(0.4))
                .frame(width: radius, height: radius)
                .offset(knob)
        }
        .frame(width: radius * 2, height: radius * 2)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    var t = g.translation
                    let dist = sqrt(t.width * t.width + t.height * t.height)
                    if dist > radius {
                        t.width = t.width / dist * radius
                        t.height = t.height / dist * radius
                    }
                    knob = t
                    value = SIMD2<Float>(
                        Float(t.width / radius),
                        Float(-t.height / radius)
                    )
                }
                .onEnded { _ in
                    knob = .zero
                    value = .zero
                }
        )
    }
}