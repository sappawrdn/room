//
//  RoomMaterials.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 01/07/26.
//

import RealityKit
import UIKit

enum RoomMaterials {
    
    static func wall() -> SimpleMaterial {
        var mat = SimpleMaterial()
        if let tex = try? TextureResource.load(named: "Wall1") {
            mat.color = .init(tint: .white, texture: .init(tex))
        } else {
            mat.color = .init(tint: .init(white: 0.7, alpha: 1.0))
        }
        mat.metallic = 0
        mat.roughness = 1
        return mat
    }
    
    static func floor() -> SimpleMaterial {
        var mat = SimpleMaterial()
        if let tex = try? TextureResource.load(named: "Floor") {
            mat.color = .init(tint: .white, texture: .init(tex))
        } else {
            mat.color = .init(tint: .gray)
        }
        mat.metallic = 0
        mat.roughness = 1
        return mat
    }
    
    static func ceiling() -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        let backroomsMaskColor = UIColor(red: 0.85, green: 0.82, blue: 0.65, alpha: 1.0)
        
        if let baseTex = try? TextureResource.load(named: "Ceiling") {
            mat.baseColor = .init(tint: backroomsMaskColor, texture: .init(baseTex))
        } else {
            mat.baseColor = .init(tint: backroomsMaskColor)
        }
        
        mat.metallic  = .init(floatLiteral: 0)
        mat.roughness = .init(floatLiteral: 1)
        mat.specular  = .init(floatLiteral: 0)
        return mat
    }
}
