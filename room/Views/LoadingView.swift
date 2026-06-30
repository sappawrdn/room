//
//  LoadingView.swift
//  room
//
//  Created by Muhammad Saffa Wardana on 29/06/26.
//

import SwiftUI

struct LoadingView: View {
    var duration: Double = 10.0      // <-- atur lama loading di sini
    var onFinish: () -> Void

    @State private var progress: CGFloat = 0
    @State private var dim = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 26) {
                Text("PROJECT S")
                    .font(.system(.title2, design: .monospaced).weight(.light))
                    .tracking(8)
                    .foregroundStyle(.white.opacity(dim ? 0.32 : 0.7))

                // garis tipis keisi pelan (moody, bukan bar tebal)
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.white.opacity(0.12))
                        .frame(width: 180, height: 1.5)
                    Rectangle()
                        .fill(.white.opacity(0.6))
                        .frame(width: 180 * progress, height: 1.5)
                }

                Text("MEMUAT")
                    .font(.system(.caption2, design: .monospaced))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: duration)) { progress = 1 }
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                dim = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                onFinish()
            }
        }
    }
}
