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
        let half = roomSize / 2
        
        // ===== Dinding =====
        var wallMat = SimpleMaterial()
        if let tex = try? TextureResource.load(named: "Wall1") {
            wallMat.color = .init(tint: .white, texture: .init(tex))
        } else {
            wallMat.color = .init(tint: .init(white: 0.7, alpha: 1.0))
        }
        wallMat.metallic = 0
        wallMat.roughness = 1
        
        // ===== Lantai =====
        var floorMat = SimpleMaterial()
        if let tex = try? TextureResource.load(named: "Floor") {
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
        
        // ===== Ceiling: di-tile biar grid panel kecil & rapi (kayak referensi) =====
        var ceilingMat = PhysicallyBasedMaterial()
        if let baseTex = try? TextureResource.load(named: "Ceiling") {
            ceilingMat.baseColor = .init(tint: .white, texture: .init(baseTex))
        } else {
            ceilingMat.baseColor = .init(
                tint: .init(red: 0.85, green: 0.82, blue: 0.73, alpha: 1.0)
            )
        }
        if let lightTex = try? TextureResource.load(named: "Ceiling-Light-Only")
        {
            ceilingMat.emissiveColor = .init(
                color: .white,
                texture: .init(lightTex)
            )
            ceilingMat.emissiveIntensity = 1.0  // <-- knob glow lampu (kecilin kalau masih bloom)
        }
        ceilingMat.metallic = .init(floatLiteral: 0)
        ceilingMat.roughness = .init(floatLiteral: 1)
        
        // 1 kotak = 1 gambar grid 6x6. Kecilin ceilTileSize biar tile makin kecil & rapet
        let ceilTileSize: Float = 5.0
        let ceilCount = Int((roomSize / ceilTileSize).rounded())
        let ceilStart = -roomSize / 2 + ceilTileSize / 2
        for ix in 0..<ceilCount {
            for iz in 0..<ceilCount {
                let panel = ModelEntity(
                    mesh: .generatePlane(
                        width: ceilTileSize,
                        depth: ceilTileSize
                    ),
                    materials: [ceilingMat]
                )
                panel.position = [
                    ceilStart + Float(ix) * ceilTileSize,
                    roomHeight,
                    ceilStart + Float(iz) * ceilTileSize,
                ]
                panel.orientation = simd_quatf(angle: .pi, axis: [1, 0, 0])
                root.addChild(panel)
            }
        }
        
        // ===== Tembok (Di-tile / Looping biar tidak stretch) =====
        let wallTileSize: Float = 4.5
        let wallTileCount = Int(ceil(roomSize / wallTileSize))
        let totalWallLength = Float(wallTileCount) * wallTileSize
        let wallStart = -totalWallLength / 2 + wallTileSize / 2
        
        func makeWallX(zPos: Float) {
            for i in 0..<wallTileCount {
                let xPos = wallStart + Float(i) * wallTileSize
                let wall = ModelEntity(
                    mesh: .generateBox(width: wallTileSize, height: roomHeight, depth: wallThickness),
                    materials: [wallMat]
                )
                wall.position = [xPos, roomHeight / 2, zPos]
                root.addChild(wall)
            }
        }
        
        func makeWallZ(xPos: Float) {
            for i in 0..<wallTileCount {
                let zPos = wallStart + Float(i) * wallTileSize
                let wall = ModelEntity(
                    mesh: .generateBox(width: wallThickness, height: roomHeight, depth: wallTileSize),
                    materials: [wallMat]
                )
                wall.position = [xPos, roomHeight / 2, zPos]
                root.addChild(wall)
            }
        }
        
        makeWallX(zPos: -half)
        makeWallX(zPos: half)
        makeWallZ(xPos: -half)
        makeWallZ(xPos: half)
        
        // ===== Senter =====
        let flashlight = SpotLight()
        flashlight.light.color = .white
        flashlight.light.intensity = 8000
        flashlight.light.innerAngleInDegrees = 40
        flashlight.light.outerAngleInDegrees = 60
        flashlight.light.attenuationRadius = 15
        camera.addChild(flashlight)
        
        camera.position = [0, 1.6, 0]
        root.addChild(camera)
        
        // ===== Monster =====
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
