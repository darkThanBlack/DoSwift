//
//  PerfFrameSource.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

extension DO {

    final class PerfFrameSource {

        struct Sample {
            let t: TimeInterval
            let fps: Double
            let slow: Int
            let frozen: Int
            let frames: Int
        }

        let interval: TimeInterval = 1

        private(set) var points: [DO.TrendPoint] = []

        private(set) var samples: [Sample] = []

        var onChange: (() -> Void)?

        let nominal: Double

        private var link: CADisplayLink?
        private var lastTimestamp: CFTimeInterval = 0
        private var windowStart: CFTimeInterval = 0
        private var frames = 0
        private var slowFrames = 0
        private var frozenFrames = 0

        init() {
            let screen = DO.Core.shared.appWindow?.windowScene?.screen ?? UIScreen.main
            nominal = Double(max(screen.maximumFramesPerSecond, 60))
        }

        func start() {
            guard link == nil else { return }

            resetWindow()
            let link = CADisplayLink(target: self, selector: #selector(tick))
            link.add(to: .main, forMode: .common)
            self.link = link
        }

        func stop() {
            link?.invalidate()
            link = nil
            resetWindow()
        }

        private func resetWindow() {
            lastTimestamp = 0
            windowStart = CACurrentMediaTime()
            frames = 0
            slowFrames = 0
            frozenFrames = 0
        }

        private var slowThreshold: CFTimeInterval {
            return 1.0 / max(nominal - 1, 1)
        }

        private let frozenThreshold: CFTimeInterval = 0.7

        @objc private func tick(_ link: CADisplayLink) {
            let now = CACurrentMediaTime()
            defer { lastTimestamp = now }

            guard lastTimestamp > 0 else { return }

            let delta = now - lastTimestamp
            frames += 1
            if delta > frozenThreshold {
                frozenFrames += 1
                slowFrames += 1
            } else if delta > slowThreshold {
                slowFrames += 1
            }

            let elapsed = now - windowStart
            guard elapsed >= interval else { return }

            let measured = Double(frames) / elapsed
            let value = slowFrames == 0 ? nominal : measured

            points.append(DO.TrendPoint(t: now, v: value))
            samples.append(Sample(t: now, fps: value, slow: slowFrames, frozen: frozenFrames, frames: frames))

            frames = 0
            slowFrames = 0
            frozenFrames = 0
            windowStart = now

            onChange?()
        }
    }
}
