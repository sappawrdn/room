//
//  RoomFloor.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 01/07/26.
//

import RealityKit

enum RoomFloor {

    static func build(root: Entity, roomSize: Float) {
        let mat      = RoomMaterials.floor()
        let tileSize: Float = 2.5
        let tileCount       = Int(ceil(roomSize / tileSize))
        let totalLength     = Float(tileCount) * tileSize
        let start           = -totalLength / 2 + tileSize / 2

        for ix in 0..<tileCount {
            for iz in 0..<tileCount {
                let tile = ModelEntity(
                    mesh: .generatePlane(width: tileSize + 0.02, depth: tileSize + 0.02),
                    materials: [mat]
                )
                tile.position = [
                    start + Float(ix) * tileSize,
                    0,
                    start + Float(iz) * tileSize,
                ]
                root.addChild(tile)
            }
        }
    }
}
