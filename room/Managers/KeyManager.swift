//
//  KeyManager.swift
//  room
//
//  Created by Muhammad Saffa Wardana on 29/06/26.
//

import RealityKit
import simd
import UIKit

class KeyManager {
    struct Key {
        let entity: ModelEntity
        let position: SIMD3<Float>
        var collected: Bool
    }

    var keys: [Key] = []
    var heldCount: Int = 1
    var interactRange: Float = 1.8

    var totalKeys: Int {
        heldCount + keys.filter { $0.collected }.count
    }

    func build(root: Entity, roomSize: Float) {
        let spots: [SIMD3<Float>] = [
            [-6, 1.0, -6],   
            [6, 1.0, 5]
        ]
        for spot in spots {
            let e = ModelEntity(
                mesh: .generateBox(size: 0.3),
                materials: [UnlitMaterial(color: .yellow)]
            )
            e.position = spot
            root.addChild(e)
            keys.append(Key(entity: e, position: spot, collected: false))
        }
    }

    func nearbyKey(playerPos: SIMD3<Float>) -> Int? {
        for (i, k) in keys.enumerated() where !k.collected {
            let dx = k.position.x - playerPos.x
            let dz = k.position.z - playerPos.z
            if sqrt(dx * dx + dz * dz) < interactRange { return i }
        }
        return nil
    }

    func collect(index: Int) -> Int {
        guard keys.indices.contains(index), !keys[index].collected else { return totalKeys }
        keys[index].collected = true
        keys[index].entity.isEnabled = false
        return totalKeys
    }
}
