//
//  ScreenSampler.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/10
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    enum ScreenSampler {

        static func snapshot(of window: UIWindow?) -> UIImage? {
            guard let window = window else { return nil }

            let bounds = window.bounds
            guard bounds.width > 0, bounds.height > 0 else { return nil }

            let format = UIGraphicsImageRendererFormat.default()
            format.scale = 1
            format.opaque = false

            return UIGraphicsImageRenderer(size: bounds.size, format: format).image { _ in
                window.drawHierarchy(in: bounds, afterScreenUpdates: false)
            }
        }

        static func color(at point: CGPoint, in image: UIImage?) -> UIColor? {
            guard let cgImage = image?.cgImage else { return nil }

            let pixel = CGRect(x: point.x.rounded(.down), y: point.y.rounded(.down), width: 1, height: 1)
            guard let one = cgImage.cropping(to: pixel) else { return nil }

            var data = [UInt8](repeating: 0, count: 4)
            let drawn = data.withUnsafeMutableBytes { raw -> Bool in
                guard let context = CGContext(
                    data: raw.baseAddress,
                    width: 1, height: 1,
                    bitsPerComponent: 8, bytesPerRow: 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                        | CGBitmapInfo.byteOrder32Big.rawValue
                ) else { return false }

                context.setBlendMode(.copy)
                context.draw(one, in: CGRect(x: 0, y: 0, width: 1, height: 1))
                return true
            }
            guard drawn else { return nil }

            let alpha = CGFloat(data[3]) / 255
            guard alpha > 0 else { return nil }

            func channel(_ value: UInt8) -> CGFloat {
                min(1.0, CGFloat(value) / 255 / alpha)
            }

            return UIColor(
                red: channel(data[0]),
                green: channel(data[1]),
                blue: channel(data[2]),
                alpha: alpha
            )
        }
    }
}
