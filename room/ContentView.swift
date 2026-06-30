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

enum QTEReason {
    case proximity
    case insanity
}

struct ContentView: View {
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
    @State var isLoading = false

    @State var haptics = HapticManager()
    @State var audio = PHASEManager()
    @State var entityBrain = EntityBrain()
    @State var keyManager = KeyManager()
    @State var insanity: Float = 0
    @State var heartTimer: Float = 0

    @State var keyCount: Int = 1
    @State var nearbyKey: Int? = nil

    // QTE + catch
    @State var showQTE = false
    @State var qteReason: QTEReason? = nil
    @State var qteCooldown: Float = 0
    @State var catches: Int = 0
    @State var isGameOver = false
    
    @State var insanityLatched = false 

    let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    let roomSize: Float = 20
    let wallThickness: Float = 0.2
    let playerRadius: Float = 0.3
    
    // Penalty ladder: makin banyak catch, kontrol makin berat
        var controlFactor: Float {
            switch catches {
            case 0: return 1.0
            case 1: return 0.6
            default: return 0.45
            }
        }

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
                    keyManager.build(root: root, roomSize: roomSize)
                    content.add(root)
                }
                .frame(width: frameWidth, height: frameHeight)
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                                                    guard isPlaying else { return }
                                                    yaw = baseYaw + Float(-value.translation.width) * 0.005 * controlFactor
                                                    pitch = basePitch + Float(-value.translation.height) * 0.005 * controlFactor
                                                }
                        .onEnded { _ in
                            baseYaw = yaw
                            basePitch = pitch
                        }
                )

                if isPlaying, !showQTE {
                    GameOverlayView(
                        frameWidth: frameWidth,
                        frameHeight: frameHeight,
                        insanity: insanity,
                        moveInput: $moveInput
                    )
                }
                
                // Penalty catch ke-2: penglihatan nyempit (tunnel vision)
                                if isPlaying, catches >= 2 {
                                    RadialGradient(
                                        colors: [.clear, .clear, .black],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 300
                                    )
                                    .frame(width: frameWidth, height: frameHeight)
                                    .clipped()
                                    .allowsHitTesting(false)
                                }

                if !isPlaying && !isLoading {
                    StartMenuView {
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            audio.start()
                            entityBrain.roomSize = roomSize
                            entityBrain.start()
                        }
                    }
                }

                // Key pips + catch marks
                if isPlaying {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { i in
                                Circle()
                                    .fill(i < keyCount ? Color.yellow.opacity(0.9) : Color.white.opacity(0.2))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { i in
                                Text("✕")
                                    .font(.caption2.bold())
                                    .foregroundStyle(i < catches ? Color.red.opacity(0.9) : Color.white.opacity(0.2))
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 36)
                }

                // Tombol AMBIL KUNCI
                if isPlaying, nearbyKey != nil, !showQTE {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                if let idx = nearbyKey {
                                    let total = keyManager.collect(index: idx)
                                    keyCount = total
                                    entityBrain.onKeyCollected(totalKeys: total)
                                    nearbyKey = nil
                                    // HOOK designer: spawn section baru di sini nanti
                                }
                            } label: {
                                Text("AMBIL KUNCI")
                                    .font(.callout.bold())
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .background(.yellow.opacity(0.85))
                                    .foregroundStyle(.black)
                                    .clipShape(Capsule())
                            }
                            .padding(.trailing, 40)
                            .padding(.bottom, 40)
                        }
                    }
                }

                // Tombol debug SEMENTARA
                if isPlaying, !showQTE {
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Button {
                                    entityBrain.debugCycle()
                                } label: {
                                    Text("STATE: \(entityBrain.currentStateName)  ↻")
                                        .font(.caption.monospaced().bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(.black.opacity(0.55))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(.white.opacity(0.4), lineWidth: 1))
                                }
                                Button {
                                    qteReason = nil   // tes murni, ga ada konsekuensi
                                    showQTE = true
                                } label: {
                                    Text("TEST QTE")
                                        .font(.caption.monospaced().bold())
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(.black.opacity(0.55))
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(.white.opacity(0.4), lineWidth: 1))
                                }
                            }
                            .padding(.top, 14)
                            .padding(.trailing, 16)
                        }
                        Spacer()
                    }
                }

                // QTE overlay
                if showQTE {
                    QTEView { passed in
                        showQTE = false
                        qteCooldown = 1.5
                        let reason = qteReason
                        qteReason = nil
                        guard let reason else { return }   // tes murni, skip konsekuensi
                        if passed {
                            switch reason {
                            case .proximity: entityBrain.stun(seconds: 4)
                            case .insanity: break   // selamat
                            }
                        } else {
                            catches += 1
                            if catches >= 3 { isGameOver = true }
                        }
                    }
                }

                // Loading
                if isLoading {
                    LoadingView(duration: 2.0) {
                        isLoading = false
                        withAnimation(.easeInOut(duration: 1.2)) {
                            isPlaying = true
                        }
                    }
                    .transition(.opacity)
                }

                if isGameOver {
                                    GameOverView {
                                        isGameOver = false
                                        isPlaying = false
                                        catches = 0
                                        insanity = 0
                                    }
                                }
            }
        }
        .ignoresSafeArea()
        .onReceive(ticker) { _ in
            tick()
        }
    }
}
