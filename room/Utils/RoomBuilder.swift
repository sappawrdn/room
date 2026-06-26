//
//  RoomBuilder.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 26/06/26.
//


import RealityKit
import SwiftUI

enum RoomBuilder {
    static func build(root: Entity, roomSize: Float, wallThickness: Float, camera: PerspectiveCamera, monster: ModelEntity) {
        let half = roomSize / 2
        var wallMat = SimpleMaterial()
        if let tex = try? TextureResource.load(named: "wall") {
            wallMat.color = .init(tint: .white, texture: .init(tex))
        } else {
            wallMat.color = .init(tint: .init(white: 0.7, alpha: 1.0))
        }
        wallMat.metallic = 0
        wallMat.roughness = 1

        var floorMat = SimpleMaterial()
        if let tex = try? TextureResource.load(named: "floor") {
            floorMat.color = .init(tint: .white, texture: .init(tex))
        } else {
            floorMat.color = .init(tint: .gray)
        }
        floorMat.metallic = 0
        floorMat.roughness = 1
        
        let tileSize: Float = 2.5 
        let tileCount = Int((roomSize / tileSize).rounded())
        let startPos = -roomSize / 2 + tileSize / 2
        for ix in 0..<tileCount {
            for iz in 0..<tileCount {
                let tile = ModelEntity(
                    mesh: .generatePlane(width: tileSize, depth: tileSize),
                    materials: [floorMat]
                )
                tile.position = [
                    startPos + Float(ix) * tileSize,
                    0,
                    startPos + Float(iz) * tileSize,
                ]
                root.addChild(tile)
            }
        }

        let ceiling = ModelEntity(
            mesh: .generatePlane(width: roomSize, depth: roomSize),
            materials: [SimpleMaterial(color: .init(white: 0.5, alpha: 1.0), isMetallic: false)]
        )
        ceiling.position = [0, 3, 0]
        ceiling.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
        root.addChild(ceiling)

        func makeWall(w: Float, d: Float, pos: SIMD3<Float>) {
            let wall = ModelEntity(
                mesh: .generateBox(width: w, height: 3, depth: d),
                materials: [wallMat]
            )
            wall.position = pos
            root.addChild(wall)
        }
        makeWall(w: roomSize, d: wallThickness, pos: [0, 1.5, -half])
        makeWall(w: roomSize, d: wallThickness, pos: [0, 1.5, half])
        makeWall(w: wallThickness, d: roomSize, pos: [-half, 1.5, 0])
        makeWall(w: wallThickness, d: roomSize, pos: [half, 1.5, 0])

        let light = DirectionalLight()
        light.light.intensity = 2000
        light.look(at: [0, 0, 0], from: [2, 4, 2], relativeTo: nil)
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
                materials: [SimpleMaterial(color: .red, isMetallic: false)]
            )
        }
    }
}