//
//  ContentView.swift
//  room
//
//  Created by Muhammad Saffa Wardana on 24/06/26.
//

import AVFoundation
import Combine
import CoreHaptics
import PHASE
import RealityKit
import SwiftUI

struct ContentView: View {
    // Note: 'private' dihapus agar file ContentView+GameLoop.swift bisa membaca variable ini
    @State var yaw: Float = 0
    @State var pitch: Float = 0
    @State var baseYaw: Float = 0
    @State var basePitch: Float = 0
    @State var camera = PerspectiveCamera()
    @State var moveInput: SIMD2<Float> = .zero
    @State var monster = ModelEntity()
    @State var monsterTarget: SIMD3<Float> = [3, 0.8, 3]

    @State var monsterKnownPos: SIMD3<Float> = [3, 0.8, 3]
    @State var stillTime: Float = 0

    @State var isPlaying = false

    @State var haptics = HapticManager()
    @State var audio = PHASEManager()
    @State var insanity: Float = 0
    @State var heartTimer: Float = 0

    let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    let roomSize: Float = 20
    let wallThickness: Float = 0.2
    let playerRadius: Float = 0.3

    var body: some View {
        GeometryReader { geo in
            let targetRatio: CGFloat = 4.0 / 3.0
            let screenRatio = geo.size.width / geo.size.height
            let ratio43Width = screenRatio > targetRatio ? geo.size.height * targetRatio : geo.size.width
            let ratio43Height = screenRatio > targetRatio ? geo.size.height : geo.size.width / targetRatio

            let frameWidth = isPlaying ? ratio43Width : geo.size.width
            let frameHeight = isPlaying ? ratio43Height : geo.size.height

            ZStack {
                Color.black
                Color(white: 0.13)
                    .frame(width: frameWidth, height: frameHeight)

                RealityView { content in
                    let root = Entity()
                    RoomBuilder.build(
                        root: root,
                        roomSize: roomSize,
                        wallThickness: wallThickness,
                        camera: camera,
                        monster: monster
                    )
                    content.add(root)
                }
                .frame(width: frameWidth, height: frameHeight)
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard isPlaying else { return }
                            yaw = baseYaw + Float(-value.translation.width) * 0.005
                            pitch = basePitch + Float(-value.translation.height) * 0.005
                        }
                        .onEnded { _ in
                            baseYaw = yaw
                            basePitch = pitch
                        }
                )

                if isPlaying {
                    GameOverlayView(
                        frameWidth: frameWidth,
                        frameHeight: frameHeight,
                        insanity: insanity,
                        moveInput: $moveInput
                    )
                } else {
                    StartMenuView {
                        audio.start()
                        withAnimation(.easeInOut(duration: 1.2)) {
                            isPlaying = true
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .onReceive(ticker) { _ in
            tick() // Fungsinya sekarang ada di file ContentView+GameLoop.swift
        }
    }
}
