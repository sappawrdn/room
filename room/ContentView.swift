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
    @State private var yaw: Float = 0
    @State private var pitch: Float = 0
    @State private var baseYaw: Float = 0
    @State private var basePitch: Float = 0
    @State private var camera = PerspectiveCamera()
    @State private var moveInput: SIMD2<Float> = .zero
    @State private var monster = ModelEntity()
    @State private var monsterTarget: SIMD3<Float> = [3, 0.8, 3]

    @State private var monsterKnownPos: SIMD3<Float> = [3, 0.8, 3]
    @State private var stillTime: Float = 0

    @State private var isPlaying = false

    @State private var haptics = HapticManager()
    @State private var audio = PHASEManager()
    @State private var insanity: Float = 0
    @State private var heartTimer: Float = 0

    let ticker = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
        .autoconnect()

    let roomSize: Float = 20
    let wallThickness: Float = 0.2
    let playerRadius: Float = 0.3

    var body: some View {
        GeometryReader { geo in
            let targetRatio: CGFloat = 4.0 / 3.0
            let screenRatio = geo.size.width / geo.size.height
            let ratio43Width =
                screenRatio > targetRatio
                ? geo.size.height * targetRatio : geo.size.width
            let ratio43Height =
                screenRatio > targetRatio
                ? geo.size.height : geo.size.width / targetRatio

            let frameWidth = isPlaying ? ratio43Width : geo.size.width
            let frameHeight = isPlaying ? ratio43Height : geo.size.height

            ZStack {
                Color.black
                Color(white: 0.13)
                    .frame(width: frameWidth, height: frameHeight)

                RealityView { content in
                    let root = Entity()
                    let half = roomSize / 2
                    var wallMat = SimpleMaterial()
                    if let tex = try? TextureResource.load(named: "wall") {
                        wallMat.color = .init(tint: .white, texture: .init(tex))
                    } else {
                        wallMat.color = .init(
                            tint: .init(white: 0.7, alpha: 1.0)
                        )
                    }
                    wallMat.metallic = 0
                    wallMat.roughness = 1

                    var floorMat = SimpleMaterial()
                    if let tex = try? TextureResource.load(named: "floor") {
                        floorMat.color = .init(
                            tint: .white,
                            texture: .init(tex)
                        )
                    } else {
                        floorMat.color = .init(tint: .gray)
                    }
                    floorMat.metallic = 0
                    floorMat.roughness = 1
                    let floor = ModelEntity(
                        mesh: .generatePlane(width: roomSize, depth: roomSize),
                        materials: [floorMat]
                    )
                    root.addChild(floor)

                    let ceiling = ModelEntity(
                        mesh: .generatePlane(width: roomSize, depth: roomSize),
                        materials: [
                            SimpleMaterial(
                                color: .init(white: 0.5, alpha: 1.0),
                                isMetallic: false
                            )
                        ]
                    )
                    ceiling.position = [0, 3, 0]
                    ceiling.orientation = simd_quatf(
                        angle: .pi,
                        axis: [1, 0, 0]
                    )
                    root.addChild(ceiling)

                    func makeWall(w: Float, d: Float, pos: SIMD3<Float>) {
                        let wall = ModelEntity(
                            mesh: .generateBox(width: w, height: 3, depth: d),
                            materials: [wallMat]
                        )
                        wall.position = pos
                        root.addChild(wall)
                    }
                    makeWall(
                        w: roomSize,
                        d: wallThickness,
                        pos: [0, 1.5, -half]
                    )
                    makeWall(
                        w: roomSize,
                        d: wallThickness,
                        pos: [0, 1.5, half]
                    )
                    makeWall(
                        w: wallThickness,
                        d: roomSize,
                        pos: [-half, 1.5, 0]
                    )
                    makeWall(
                        w: wallThickness,
                        d: roomSize,
                        pos: [half, 1.5, 0]
                    )

                    let light = DirectionalLight()
                    light.light.intensity = 2000
                    light.look(
                        at: [0, 0, 0],
                        from: [2, 4, 2],
                        relativeTo: nil
                    )
                    root.addChild(light)

                    camera.position = [0, 1.6, 0]
                    root.addChild(camera)

                    monster.position = [3, 0, 3]
                    root.addChild(monster)

                    if let bagman = try? Entity.load(named: "PSX_BagMan") {
                        bagman.scale = [1, 1, 1]
                        bagman.position = [0, 0, 0]
                        monster.addChild(bagman)
                    } else {
                        monster.model = ModelComponent(
                            mesh: .generateBox(size: 0.6),
                            materials: [
                                SimpleMaterial(color: .red, isMetallic: false)
                            ]
                        )
                    }

                    content.add(root)
                }
                .frame(width: frameWidth, height: frameHeight)
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard isPlaying else { return }
                            yaw =
                                baseYaw + Float(-value.translation.width)
                                * 0.005
                            pitch =
                                basePitch + Float(-value.translation.height)
                                * 0.005
                        }
                        .onEnded { _ in
                            baseYaw = yaw
                            basePitch = pitch
                        }
                )

                if isPlaying {
                    VStack {
                        Text("INSANITY \(Int(insanity * 100))%")
                            .font(.caption.monospaced())
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.top, 10)
                        Spacer()
                    }
                }

                if isPlaying {
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

                if !isPlaying {
                    ZStack {
                        Color.black
                        Button("PLAY") {
                            audio.start()
                            withAnimation(.easeInOut(duration: 1.2)) {
                                isPlaying = true
                            }
                        }
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                    }
                    .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .onReceive(ticker) { _ in
            tick()
        }
    }

    func tick() {
        camera.orientation =
            simd_quatf(angle: yaw, axis: [0, 1, 0])
            * simd_quatf(angle: pitch, axis: [1, 0, 0])

        guard isPlaying else { return }

        let dt: Float = 1.0 / 60.0
        let moving = length(moveInput) > 0.1

        let yawRot = simd_quatf(angle: yaw, axis: [0, 1, 0])
        let forward = yawRot.act(SIMD3<Float>(0, 0, -1))
        let right = yawRot.act(SIMD3<Float>(1, 0, 0))
        let speed: Float = 2.5

        var pos = camera.position
        pos += (forward * moveInput.y + right * moveInput.x) * speed * dt
        pos.y = 1.6
        let limit = roomSize / 2 - wallThickness / 2 - playerRadius
        pos.x = min(max(pos.x, -limit), limit)
        pos.z = min(max(pos.z, -limit), limit)
        camera.position = pos

        // Monster: ngejar kalau denger pemain (pas gerak), wander kalau pemain diem
        // ----- Monster AI: berburu lewat suara, tebakan bisa basi & menyempit -----
        let playerPos = SIMD3<Float>(camera.position.x, 0.8, camera.position.z)

        if moving {
            // Pemain bersuara: monster ngelacak, tapi tebakannya rada ketinggalan
            // (makin kecil trackRate makin "telat", makin gampang lu slip pas pindah)
            let trackRate: Float = 2.0
            monsterKnownPos +=
                (playerPos - monsterKnownPos) * min(trackRate * dt, 1)
            stillTime = 0
        } else {
            // Pemain diem: monster cuma pegang posisi terakhir kedengeran
            stillTime += dt
            // Tapi nongkrong kelamaan = tebakannya pelan pelan nyamperin lu beneran
            if stillTime > 5 {  // <-- detik "grace" sebelum dia mulai nyaut
                let closing: Float = 0.3 * dt  // <-- makin gede makin cepet nemu lu
                monsterKnownPos += (playerPos - monsterKnownPos) * closing
            }
        }

        // Monster gerak menuju tebakannya
        let toKnown = SIMD3<Float>(
            monsterKnownPos.x - monster.position.x,
            0,
            monsterKnownPos.z - monster.position.z
        )
        let knownDist = length(toKnown)
        let monsterSpeed: Float = moving ? (1.0 + 1.2 * insanity) : 0.9

        if knownDist > 0.4 {
            let dir = toKnown / knownDist
            var mp = monster.position + dir * monsterSpeed * dt
            mp.y = 0.8
            monster.position = mp
        } else {
            // Udah nyampe tebakan tapi pemain ga ada: ubek ubek sekitar situ
            let toSearch = SIMD3<Float>(
                monsterTarget.x - monster.position.x,
                0,
                monsterTarget.z - monster.position.z
            )
            let searchDist = length(toSearch)
            if searchDist < 0.4 {
                let lim = roomSize / 2 - 1
                let sx = min(
                    max(monsterKnownPos.x + Float.random(in: -2.5...2.5), -lim),
                    lim
                )
                let sz = min(
                    max(monsterKnownPos.z + Float.random(in: -2.5...2.5), -lim),
                    lim
                )
                monsterTarget = [sx, 0.8, sz]
            } else {
                let dir = toSearch / searchDist
                var mp = monster.position + dir * 0.9 * dt
                mp.y = 0.8
                monster.position = mp
            }
        }

        let mdx = monster.position.x - camera.position.x
        let mdz = monster.position.z - camera.position.z
        let distMonster = sqrt(mdx * mdx + mdz * mdz)

        let nearRange: Float = 6
        if distMonster < nearRange {
            let closeness = (nearRange - distMonster) / nearRange
            insanity = min(insanity + closeness * 0.18 * dt, 1.0)
        } else if moving {
            insanity = min(insanity + 0.04 * dt, 1.0)
        } else {
            insanity = max(insanity - 0.12 * dt, 0.0)
        }

        let bpm: Float = 60 + 90 * insanity
        let beatInterval = 60.0 / bpm
        let beatIntensity = 0.85 + 0.15 * insanity
        heartTimer += dt
        if heartTimer >= beatInterval {
            heartTimer = 0
            haptics.playHeartbeat(intensity: beatIntensity)
            audio.playHeartbeatSound(volume: beatIntensity)
        }

        audio.updateListener(
            position: camera.position,
            orientation: camera.orientation
        )
        audio.updateEntity(position: monster.position)
    }
}

// Mesin haptic detak jantung
class HapticManager {
    var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("Haptic engine gagal start: \(error)")
        }
    }

    func playHeartbeat(intensity: Float) {
        guard let engine = engine else { return }
        do {
            try engine.start()
            let strong = min(intensity * 1.3, 1.0)
            let lub = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: strong
                    ),
                    CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: 0.25
                    ),
                    CHHapticEventParameter(parameterID: .attackTime, value: 0),
                    CHHapticEventParameter(
                        parameterID: .decayTime,
                        value: 0.18
                    ),
                    CHHapticEventParameter(parameterID: .sustained, value: 0),
                ],
                relativeTime: 0,
                duration: 0.22
            )
            let dub = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: strong * 0.9
                    ),
                    CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: 0.2
                    ),
                    CHHapticEventParameter(parameterID: .attackTime, value: 0),
                    CHHapticEventParameter(
                        parameterID: .decayTime,
                        value: 0.16
                    ),
                    CHHapticEventParameter(parameterID: .sustained, value: 0),
                ],
                relativeTime: 0.22,
                duration: 0.2
            )
            let pattern = try CHHapticPattern(
                events: [lub, dub],
                parameters: []
            )
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Detak gagal: \(error)")
        }
    }
}

// Mesin spatial audio PHASE
class PHASEManager {
    let engine = PHASEEngine(updateMode: .automatic)
    var source: PHASESource?
    var listener: PHASEListener?
    var event: PHASESoundEvent?
    var started = false

    // entity
    var entitySource: PHASESource?
    var entityGain: Double = 0.6  // <-- pelanin/kencengin entity di sini (0.6 = lebih pelan biar detak ga ketutup)

    // detak jantung (AVAudioEngine, low latency biar sinkron sama haptic)
    let heartEngine = AVAudioEngine()
    let heartNode = AVAudioPlayerNode()
    var heartBuffer: AVAudioPCMBuffer?
    var heartReady = false
    var heartGain: Float = 3.2  // <-- kencengin/pelanin detak di sini (makin gede makin kenceng)

    func start() {
        guard !started else { return }
        started = true

        do {
            // Audio session: biar low latency + tetep bunyi walau HP silent
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback)
            try? session.setActive(true)

            guard
                let url = Bundle.main.url(
                    forResource: "hum",
                    withExtension: "wav"
                )
            else {
                print("hum.wav ga ketemu")
                return
            }
            try engine.assetRegistry.registerSoundAsset(
                url: url,
                identifier: "hum",
                assetType: .resident,
                channelLayout: nil,
                normalizationMode: .dynamic
            )

            let spatialPipeline = PHASESpatialPipeline(
                flags: .directPathTransmission
            )!
            let mixer = PHASESpatialMixerDefinition(
                spatialPipeline: spatialPipeline
            )
            mixer.gain = entityGain

            let sampler = PHASESamplerNodeDefinition(
                soundAssetIdentifier: "hum",
                mixerDefinition: mixer
            )
            sampler.playbackMode = .looping
            sampler.cullOption = .doNotCull
            try engine.assetRegistry.registerSoundEventAsset(
                rootNode: sampler,
                identifier: "humEvent"
            )

            let mesh = MDLMesh.newIcosahedron(
                withRadius: 0.1,
                inwardNormals: false,
                allocator: nil
            )
            let shape = PHASEShape(engine: engine, mesh: mesh)
            let src = PHASESource(engine: engine, shapes: [shape])
            var t = matrix_identity_float4x4
            t.columns.3 = SIMD4<Float>(-3, 1.6, -3, 1)
            src.transform = t
            try engine.rootObject.addChild(src)
            self.source = src

            let listener = PHASEListener(engine: engine)
            listener.transform = matrix_identity_float4x4
            try engine.rootObject.addChild(listener)
            self.listener = listener

            try engine.start()

            let mixerParams = PHASEMixerParameters()
            mixerParams.addSpatialMixerParameters(
                identifier: mixer.identifier,
                source: src,
                listener: listener
            )
            let event = try PHASESoundEvent(
                engine: engine,
                assetIdentifier: "humEvent",
                mixerParameters: mixerParams
            )
            try event.start()
            self.event = event

            startEntitySound()
            setupHeartbeat()
        } catch {
            print("PHASE gagal: \(error)")
        }
    }

    func updateListener(position: SIMD3<Float>, orientation: simd_quatf) {
        var m = simd_float4x4(orientation)
        m.columns.3 = SIMD4<Float>(position.x, position.y, position.z, 1)
        listener?.transform = m
    }

    // ----- Suara entity nempel monster -----
    func startEntitySound() {
        do {
            guard
                let url = Bundle.main.url(
                    forResource: "entity",
                    withExtension: "wav"
                )
            else {
                print("entity.wav ga ketemu")
                return
            }
            try engine.assetRegistry.registerSoundAsset(
                url: url,
                identifier: "entity",
                assetType: .resident,
                channelLayout: nil,
                normalizationMode: .dynamic
            )

            let pipeline = PHASESpatialPipeline(flags: .directPathTransmission)!
            let mixer = PHASESpatialMixerDefinition(spatialPipeline: pipeline)

            let sampler = PHASESamplerNodeDefinition(
                soundAssetIdentifier: "entity",
                mixerDefinition: mixer
            )
            sampler.playbackMode = .looping
            sampler.cullOption = .doNotCull
            try engine.assetRegistry.registerSoundEventAsset(
                rootNode: sampler,
                identifier: "entityEvent"
            )

            let mesh = MDLMesh.newIcosahedron(
                withRadius: 0.1,
                inwardNormals: false,
                allocator: nil
            )
            let shape = PHASEShape(engine: engine, mesh: mesh)
            let src = PHASESource(engine: engine, shapes: [shape])
            var t = matrix_identity_float4x4
            t.columns.3 = SIMD4<Float>(3, 0.8, 3, 1)
            src.transform = t
            try engine.rootObject.addChild(src)
            self.entitySource = src

            let params = PHASEMixerParameters()
            if let listener = listener {
                params.addSpatialMixerParameters(
                    identifier: mixer.identifier,
                    source: src,
                    listener: listener
                )
            }
            let ev = try PHASESoundEvent(
                engine: engine,
                assetIdentifier: "entityEvent",
                mixerParameters: params
            )
            try ev.start()
        } catch {
            print("Entity sound gagal: \(error)")
        }
    }

    func updateEntity(position: SIMD3<Float>) {
        var m = matrix_identity_float4x4
        m.columns.3 = SIMD4<Float>(position.x, position.y, position.z, 1)
        entitySource?.transform = m
    }

    // ----- Suara detak jantung (low latency, sinkron haptic) -----
    func setupHeartbeat() {
        guard
            let url = Bundle.main.url(
                forResource: "heartbeat",
                withExtension: "wav"
            ),
            let file = try? AVAudioFile(forReading: url),
            let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
            )
        else {
            print("heartbeat.wav ga ketemu / gagal load")
            return
        }
        do {
            try file.read(into: buffer)
            heartBuffer = buffer
            heartEngine.attach(heartNode)
            heartEngine.connect(
                heartNode,
                to: heartEngine.mainMixerNode,
                format: file.processingFormat
            )
            try heartEngine.start()
            heartNode.play()
            heartReady = true
        } catch {
            print("Heart engine gagal: \(error)")
        }
    }

    func playHeartbeatSound(volume: Float) {
        guard heartReady, let buffer = heartBuffer else { return }
        heartNode.volume = min(volume * heartGain, 1.0)
        heartNode.scheduleBuffer(
            buffer,
            at: nil,
            options: .interrupts,
            completionHandler: nil
        )
    }
}

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
