//
//  afa.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//

import RealityKit
import SwiftUI

extension ContentView {
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

        // ----- Monster AI: berburu lewat suara -----
        let playerPos = SIMD3<Float>(camera.position.x, 0, camera.position.z)

        if moving {
            let trackRate: Float = 0.5
            monsterKnownPos +=
                (playerPos - monsterKnownPos) * min(trackRate * dt, 1)
            stillTime = 0
        } else {
            stillTime += dt
            if stillTime > 5 {
                let closing: Float = 0.3 * dt
                monsterKnownPos += (playerPos - monsterKnownPos) * closing
            }
        }

        let toKnown = SIMD3<Float>(
            monsterKnownPos.x - monster.position.x,
            0,
            monsterKnownPos.z - monster.position.z
        )
        let knownDist = length(toKnown)
        let monsterSpeed: Float = moving ? (0.5 + 0.5 * insanity) : 0.4
        
        if knownDist > 0.4 {
            let dir = toKnown / knownDist
            var mp = monster.position + dir * monsterSpeed * dt
            mp.y = 0
            monster.position = mp
        } else {
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
                monsterTarget = [sx, 0, sz]
            } else {
                let dir = toSearch / searchDist
                var mp = monster.position + dir * 0.9 * dt
                mp.y = 0
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
