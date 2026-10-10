//
//  ScreenSampler.swift
//  DoSwift
//
//  Created by Claude Code on 2026/10/10.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 从屏幕上「读」颜色：先把 window 的图层树栅格化成位图，再按点取样。
///
/// iOS 没有读取屏幕像素的公有 API——所有取色都建立在「把某棵图层树画进一张位图」之上，
/// 区别只在于**画谁、画多大、什么时候画**。这里选的是「只画业务 window、整屏、按需」：
///
/// - **只画业务 window**：DoSwift 自己的浮层是另一个 window，不在被画的树里，
///   于是标尺、边框环、手柄永远不会进入取色结果。这是白拿的，不需要「隐藏自己一帧」。
/// - **1x**：图像像素 == 屏幕点，`color(at:)` 的取整才有确定含义。改成设备倍率的话，
///   一个点会覆盖 4 / 9 个物理像素，CoreGraphics 会**隐式**替你降采样，而用的核、
///   所在色彩空间都不在文档里——那就成了「做了个你不知道的决定」，比任何一种
///   显式算法都糟。
/// - **按需**：由调用方决定时机（一次拖动一张），不是持续录屏。
enum ScreenSampler {

    /// 栅格化 `window` 当前显示的内容。
    ///
    /// 用 `drawHierarchy` 而不是 `layer.render(in:)`：前者走 render server，拿到的是
    /// **屏幕上此刻这一帧**，毛玻璃这类由 render server 合成的内容也在里面；后者在 CPU 侧
    /// 重走一遍图层树，动画中间态拍到的是终态值，`UIVisualEffectView` 的 backdrop 画不出来。
    /// 两者都拍不到视频 / Metal / Camera —— 那些内容不是 Core Graphics 画的。
    static func snapshot(of window: UIWindow?) -> UIImage? {
        guard let window = window else { return nil }

        let bounds = window.bounds
        guard bounds.width > 0, bounds.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { _ in
            // afterScreenUpdates: false —— 取 render server 里「此刻屏幕上的内容」。
            // true 会强制一次同步 layout + commit（主线程上一次真实的停顿），而
            // 被采的业务 window 总是已经上屏，不必付这个代价。
            window.drawHierarchy(in: bounds, afterScreenUpdates: false)
        }
    }

    /// 取 `image` 上一点的颜色。
    ///
    /// - Parameter point: **点**，与 `snapshot` 的 1x 约定配套。坐标**向下取整**到所在像素，
    ///   不做四舍五入——小数位置不会被「就近」到隔壁像素。放大镜的中心格用的是同一个取整，
    ///   所以「中心格显示的颜色」与「面板上的读数」永远是同一个像素。
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

            // 1×1 画进 1×1，完全没有缩放，读到的就是那一个像素
            context.setBlendMode(.copy)
            context.draw(one, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return true
        }
        guard drawn else { return nil }

        // 位图是预乘的：半透明像素的 RGB 已经被 alpha 乘过，要除回去才是颜色本身。
        // 8 bit 的舍入会让分量偶尔略微超过 alpha，所以夹一下。
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
