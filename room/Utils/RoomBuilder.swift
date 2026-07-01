//
//  RoomBuilder.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//

import RealityKit
import SwiftUI

enum RoomBuilder {

    static func build(
        root: Entity,
        roomSize: Float,
        wallThickness: Float,
        camera: PerspectiveCamera,
        monster: ModelEntity
    ) {
        let roomHeight: Float = 4.5

        // ===== Surfaces =====
        RoomFloor.build(root: root, roomSize: roomSize)
        RoomCeiling.build(root: root, roomSize: roomSize, roomHeight: roomHeight)
        RoomWalls.build(
            root: root,
            roomSize: roomSize,
            roomHeight: roomHeight,
            wallThickness: wallThickness
        )

        // ===== Senter (flashlight melekat ke kamera) =====
        let flashlight = SpotLight()
        flashlight.light.color               = UIColor(red: 0.85, green: 0.85, blue: 0.6, alpha: 1.0)
        flashlight.light.intensity           = 20000
        flashlight.light.innerAngleInDegrees = 40
        flashlight.light.outerAngleInDegrees = 60
        flashlight.light.attenuationRadius   = 15
        camera.addChild(flashlight)

        // ===== Kamera =====
        camera.position = [0, 1.6, 0]
        root.addChild(camera)

        // ===== Monster =====
        monster.position = [3, 0, 3]
        root.addChild(monster)
        
        if let bagman = try? Entity.load(named: "backrooms_monster2") {
            bagman.scale = [1, 1, 1]
            bagman.position = [0, 0, 0]
            monster.addChild(bagman)
        } else {
            monster.model = ModelComponent(
                mesh: .generateBox(size: 0.6),
                materials: [SimpleMaterial(color: .red, isMetallic: false)]
            )
        }
    }
}
