//
//  QTEView.swift
//  room
//
//  Created by Muhammad Saffa Wardana on 29/06/26.
//


import SwiftUI
import UIKit
import Combine

struct QTEView: View {
    var onComplete: (Bool) -> Void

    @State private var needleAngle: Double = 0       
    @State private var zoneStart: Double = 150
    private let zoneWidth: Double = 48
    @State private var successes = 0
    @State private var fails = 0
    @State private var checkActive = true
    @State private var enteredZone = false
    @State private var outcome: Bool? = nil

    private let sweepDuration: Double = 1.6
    private let needTarget = 3

    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()

            if let outcome {
                Text(outcome ? "LOLOS" : "KETANGKEP")
                    .font(.largeTitle.monospaced().bold())
                    .foregroundStyle(outcome ? .green : .red)
            } else {
                VStack(spacing: 24) {
                    Text("TAHAN DIRIMU")
                        .font(.headline.monospaced())
                        .foregroundStyle(.white.opacity(0.85))

                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 10)

                        ArcShape(startAngle: zoneStart, endAngle: zoneStart + zoneWidth)
                            .stroke(.green.opacity(0.9), style: StrokeStyle(lineWidth: 12, lineCap: .butt))

                    Color.clear
                        .frame(width: 200, height: 200)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(.white)
                                .frame(width: 3, height: 95)
                        }
                        .rotationEffect(.degrees(needleAngle))
                    }
                    .frame(width: 200, height: 200)

                    HStack(spacing: 10) {
                        ForEach(0..<needTarget, id: \.self) { i in
                            Circle()
                                .fill(i < successes ? Color.green : Color.white.opacity(0.2))
                                .frame(width: 14, height: 14)
                        }
                    }

                    Text("Ketuk pas jarum di zona hijau")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { tap() }
        .onReceive(timer) { _ in advance() }
    }

    private func advance() {
        guard checkActive, outcome == nil else { return }
        needleAngle += 360.0 / (sweepDuration * 60.0)

        // getar tipis pas jarum MASUK zona (penanda buat tangan, sightless-friendly)
        if !enteredZone, needleAngle >= zoneStart, needleAngle <= zoneStart + zoneWidth {
            enteredZone = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        if needleAngle >= 360 {
            resolve(false)   // jarum lewat tanpa diketuk = gagal
        }
    }

    private func tap() {
        guard checkActive, outcome == nil else { return }
        let hit = needleAngle >= zoneStart && needleAngle <= zoneStart + zoneWidth
        resolve(hit)
    }

    private func resolve(_ hit: Bool) {
        checkActive = false
        if hit {
            successes += 1
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        } else {
            fails += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        if successes >= needTarget { finish(true); return }
        if fails >= needTarget { finish(false); return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            needleAngle = 0
            enteredZone = false
            zoneStart = Double.random(in: 120...300)
            checkActive = true
        }
    }

    private func finish(_ ok: Bool) {
        outcome = ok
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { onComplete(ok) }
    }
}

// Arc dengan konvensi 0 = atas (jam 12), nambah searah jarum jam
struct ArcShape: Shape {
    var startAngle: Double
    var endAngle: Double
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        p.addArc(center: center,
                 radius: radius,
                 startAngle: .degrees(startAngle - 90),
                 endAngle: .degrees(endAngle - 90),
                 clockwise: false)
        return p
    }
}
