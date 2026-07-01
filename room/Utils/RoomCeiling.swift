//
//  RoomCeiling.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 01/07/26.
//

import RealityKit
import UIKit

enum RoomCeiling {

    // Tweak knobs
    private static let tileSize: Float   = 4.0   // ukuran 1 panel plafon
    private static let litPanelW: Float  = 1.0   // lebar kotak lampu visual
    private static let litPanelD: Float  = 1.0   // dalam kotak lampu visual
    private static let lightIntensity: Float        = 3500
    private static let lightAttenuationRadius: Float = 13.0

    static func build(root: Entity, roomSize: Float, roomHeight: Float) {
        buildTilesAndGlow(root: root, roomSize: roomSize, roomHeight: roomHeight)
        buildPointLights(root: root, roomSize: roomSize, roomHeight: roomHeight)
    }

    // MARK: - Ceiling tiles + visual glow panels (UnlitMaterial, ikut loop tile)

    private static func buildTilesAndGlow(root: Entity, roomSize: Float, roomHeight: Float) {
        let ceilMat = RoomMaterials.ceiling()

        let count = Int((roomSize / tileSize).rounded())
        let start = -roomSize / 2 + tileSize / 2

        for ix in 0..<count {
            for iz in 0..<count {
                let cx = start + Float(ix) * tileSize
                let cz = start + Float(iz) * tileSize

                // Base ceiling tile
                let panel = ModelEntity(
                    mesh: .generatePlane(width: tileSize, depth: tileSize),
                    materials: [ceilMat]
                )
                panel.position    = [cx, roomHeight, cz]
                panel.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                root.addChild(panel)
            }
        }
    }

    // MARK: - PointLights (tepat 8, tersebar merata di seluruh ruangan)

    private static func buildPointLights(root: Entity, roomSize: Float, roomHeight: Float) {
        let lightColor = UIColor(red: 0.85, green: 0.85, blue: 0.6, alpha: 1.0)
        let t = roomSize / 3.0

        // 8 posisi: grid 2x4 tersebar merata (4 inner + 4 outer)
        let positions: [SIMD2<Float>] = [
            [-t / 2, -t / 2],
            [ t / 2, -t / 2],
            [-t / 2,  t / 2],
            [ t / 2,  t / 2],
            [-t,     -t    ],
            [ t,     -t    ],
            [-t,      t    ],
            [ t,      t    ],
        ]

        for pos in positions {
            let light = PointLight()
            light.light.color             = lightColor
            light.light.intensity         = 20000
            light.light.attenuationRadius = 20
            light.position                = [pos.x, roomHeight - 0.3, pos.y]
            root.addChild(light)
        }
    }
}
