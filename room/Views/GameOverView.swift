//
//  GameOverView.swift
//  room
//
//  Created by Muhammad Saffa Wardana on 29/06/26.
//

import SwiftUI

struct GameOverView: View {
    var onBackToMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 30) {
                Text("GAME OVER")
                    .font(.system(.largeTitle, design: .monospaced).bold())
                    .foregroundStyle(.red.opacity(0.85))
                    .tracking(4)

                Button {
                    onBackToMenu()
                } label: {
                    Text("KEMBALI KE MENU")
                        .font(.callout.monospaced())
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .transition(.opacity)
    }
}
