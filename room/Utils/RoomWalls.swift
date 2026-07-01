//
//  RoomWalls.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 01/07/26.
//

import RealityKit

enum RoomWalls {

    static func build(
        root: Entity,
        roomSize: Float,
        roomHeight: Float,
        wallThickness: Float
    ) {
        let mat           = RoomMaterials.wall()
        let tileSize: Float  = 4.5
        let tileCount        = Int(ceil(roomSize / tileSize))
        let totalLength      = Float(tileCount) * tileSize
        let start            = -totalLength / 2 + tileSize / 2
        let half             = roomSize / 2

        // Dinding sejajar sumbu X (depan & belakang)
        func makeWallX(zPos: Float) {
            for i in 0..<tileCount {
                let wall = ModelEntity(
                    mesh: .generateBox(
                        width: tileSize,
                        height: roomHeight,
                        depth: wallThickness
                    ),
                    materials: [mat]
                )
                wall.position = [start + Float(i) * tileSize, roomHeight / 2, zPos]
                root.addChild(wall)
            }
        }

        // Dinding sejajar sumbu Z (kiri & kanan)
        func makeWallZ(xPos: Float) {
            for i in 0..<tileCount {
                let wall = ModelEntity(
                    mesh: .generateBox(
                        width: wallThickness,
                        height: roomHeight,
                        depth: tileSize
                    ),
                    materials: [mat]
                )
                wall.position = [xPos, roomHeight / 2, start + Float(i) * tileSize]
                root.addChild(wall)
            }
        }

        makeWallX(zPos: -half)
        makeWallX(zPos:  half)
        makeWallZ(xPos: -half)
        makeWallZ(xPos:  half)
    }
}
