//
//  PHASEManager.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//


import AVFoundation
import PHASE

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
            event.start()
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
            ev.start()
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
