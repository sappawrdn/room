//
//  CGhelper.swift
//  room
//
//  Created by Raffi Chaesa Ananda on 01/07/26.
//

import CoreGraphics

extension CGImage {
    static func blackSkybox(width: Int = 4, height: Int = 2) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: bytesPerRow * height) // semua 0 = hitam + alpha 0

        // set alpha jadi 255 (opaque hitam)
        for i in stride(from: 3, to: pixelData.count, by: 4) {
            pixelData[i] = 255
        }

        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!

        return context.makeImage()!
    }
}
