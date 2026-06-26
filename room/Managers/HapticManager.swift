//
//  HapticManager.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//

import CoreHaptics

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
