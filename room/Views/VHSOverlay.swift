//
//  VHSOverlay.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//


import SwiftUI

struct VHSOverlay: View {
    var grainCount: Int = 220  // turunin kalau nge-lag, naikin kalau mau lebih kotor
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard size.width > 1, size.height > 1 else { return }
                let t = timeline.date.timeIntervalSinceReferenceDate
                
                // Scanlines
                context.opacity = 0.10
                var y: CGFloat = 0
                while y < size.height {
                    context.fill(
                        Path(CGRect(x: 0, y: y, width: size.width, height: 1)),
                        with: .color(.black)
                    )
                    y += 3
                }
                
                // Grain (titik random tiap frame)
                context.opacity = 0.09
                for _ in 0..<grainCount {
                    let gx = CGFloat.random(in: 0..<size.width)
                    let gy = CGFloat.random(in: 0..<size.height)
                    context.fill(
                        Path(CGRect(x: gx, y: gy, width: 1.5, height: 1.5)),
                        with: .color(.white)
                    )
                }
                
                // VHS tracking bar (pita gerak naik turun pelan)
                context.opacity = 0.05
                let barY = CGFloat(sin(t * 0.7) * 0.5 + 0.5) * size.height
                context.fill(
                    Path(CGRect(x: 0, y: barY, width: size.width, height: 36)),
                    with: .color(.white)
                )
            }
        }
        .allowsHitTesting(false)
    }
}