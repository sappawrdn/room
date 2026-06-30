//
//  ContentView+GameLoop.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//

import RealityKit
import SwiftUI

extension ContentView {
    func tick() {
        camera.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
                           * simd_quatf(angle: pitch, axis: [1, 0, 0])

        guard isPlaying, !isGameOver else { return }

        let dt: Float = 1.0 / 60.0
        if qteCooldown > 0 { qteCooldown -= dt }

        let moving = length(moveInput) > 0.1

        if !showQTE {
            // Gerak pemain
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

            // Entity AI
            let playerPos = SIMD3<Float>(camera.position.x, 0, camera.position.z)
            entityBrain.update(monster: monster, playerPos: playerPos, dt: dt)

            // Deteksi kunci terdekat
            let nk = keyManager.nearbyKey(playerPos: playerPos)
            if nk != nearbyKey { nearbyKey = nk }

            // Jarak entity ke pemain
            let mdx = monster.position.x - camera.position.x
            let mdz = monster.position.z - camera.position.z
            let distMonster = sqrt(mdx * mdx + mdz * mdz)

            // Insanity (model lama, nanti diganti per-section)
            let nearRange: Float = 6
            if distMonster < nearRange {
                let closeness = (nearRange - distMonster) / nearRange
                insanity = min(insanity + closeness * 0.18 * dt, 1.0)
            } else if moving {
                insanity = min(insanity + 0.04 * dt, 1.0)
            } else {
                insanity = max(insanity - 0.12 * dt, 0.0)
            }

            // Pemicu QTE: entity kedeketan
            let proximityRadius: Float = 1.6
            if qteCooldown <= 0, !entityBrain.isStunned, distMonster < proximityRadius {
                qteReason = .proximity
                showQTE = true
            }
            
            if insanity < 0.8 { insanityLatched = false }
            if qteCooldown <= 0, !showQTE, !insanityLatched, insanity >= 1.0 {
                qteReason = .insanity
                showQTE = true
                insanityLatched = true
            }
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

        // PHASE
        audio.updateListener(position: camera.position, orientation: camera.orientation)
        audio.updateEntity(position: monster.position)
    }
}
