//
//  PerfTrendPlugin.swift
//  DoSwift
//
//  Created by moonShadow on 2026/10/31
//  Copyright © 2026 darkThanBlack. All rights reserved.
//
//  LICENSE: SAME AS REPOSITORY
//  Contact me: [GitHub](https://github.com/darkThanBlack)
//

import UIKit

private let trendStyleKey = "kPerfTrendStyleKey"

private let memoryMetricKey = "kPerfMemoryMetricKey"

extension DO {

    final class PerfTrendPlugin: DO.DefaultPlugin {

        static let shared = DO.PerfTrendPlugin()

        private init() {
            super.init(identifier: "performance", title: "性能", icon: UIImage(systemName: "gauge"))
        }

        static let metricCount = 3

        private let frames = DO.PerfFrameSource()
        private let cpu = DO.PerfCpuSource()
        private let memory = DO.PerfMemorySource()

        private var allCharts: [DO.TrendChart] {
            let memoryTotal = memory.totalMB ?? 512

            return [
                DO.TrendChart(
                    title: "FPS",
                    unit: "fps",
                    range: 0...frames.nominal,
                    threshold: .below(frames.nominal * 0.75),
                    interval: frames.interval,
                    tint: .systemBlue,
                    points: frames.points
                ),
                DO.TrendChart(
                    title: "CPU",
                    unit: "%",
                    range: 0...100,
                    threshold: .above(80),
                    interval: cpu.interval,
                    tint: .systemOrange,
                    points: cpu.points
                ),
                DO.TrendChart(
                    title: "内存",
                    unit: "MB",
                    range: 0...memoryTotal,
                    threshold: .above(memoryTotal * 0.8),
                    interval: memory.interval,
                    tint: .systemGreen,
                    points: memory.points
                ),
            ]
        }

        var charts: [DO.TrendChart] {
            return allCharts.enumerated()
                .filter { enabled.contains($0.offset) }
                .map(\.element)
        }

        var cpuSamples: [DO.PerfCpuSource.Sample] { cpu.samples }

        var memorySamples: [DO.PerfMemorySource.Sample] { memory.samples }

        var memoryTotalMB: Double? { memory.totalMB }

        var frameSamples: [DO.PerfFrameSource.Sample] { frames.samples }

        func chart(at index: Int) -> DO.TrendChart? {
            return allCharts.indices.contains(index) ? allCharts[index] : nil
        }

        private(set) var isVisible = false

        private weak var report: UINavigationController?

        private(set) var currentIndex = 0

        private(set) var enabled: Set<Int> = Set(0..<DO.PerfTrendPlugin.metricCount)

        private(set) var memoryMetric: DO.PerfMemoryMetric = {
            let raw = UserDefaults.standard.string(forKey: memoryMetricKey)
            return raw.flatMap(DO.PerfMemoryMetric.init(rawValue:)) ?? .footprint
        }()

        private(set) var displayStyle: DO.TrendDisplayStyle = {
            let raw = UserDefaults.standard.string(forKey: trendStyleKey)
            return raw.flatMap(DO.TrendDisplayStyle.init(rawValue:)) ?? .line
        }()

        private let trend = DO.PerfTrendView()
        private var didLayout = false
        private var lastRefresh: TimeInterval = 0

        func isEnabled(_ index: Int) -> Bool {
            return enabled.contains(index)
        }

        @discardableResult
        func setEnabled(_ isOn: Bool, for index: Int) -> Bool {
            guard index >= 0, index < DO.PerfTrendPlugin.metricCount else { return false }

            if isOn {
                enabled.insert(index)
                startSource(index)
            } else {
                guard enabled.count > 1 else { return false }
                enabled.remove(index)
                stopSource(index)

                if !enabled.contains(currentIndex) {
                    currentIndex = nextEnabled(after: currentIndex)
                }
            }

            refresh(force: true)
            return true
        }

        override func show() {
            super.show()

            isVisible = true
            layoutTrend()
            refresh(force: true)

            guard report == nil, let host = window?.rootViewController else { return }

            let navigator = UINavigationController(rootViewController: DO.PerfReportViewController())
            navigator.isModalInPresentation = true
            host.present(navigator, animated: true)
            report = navigator
        }

        override func hide() {
            isVisible = false
            refresh(force: true)

            guard report == nil else { return }
            window?.isHidden = true
        }

        func setMemoryMetric(_ metric: DO.PerfMemoryMetric) {
            guard metric != memoryMetric else { return }
            memoryMetric = metric
            UserDefaults.standard.set(metric.rawValue, forKey: memoryMetricKey)
            memory.setMetric(metric)
            refresh(force: true)
        }

        func setDisplayStyle(_ style: DO.TrendDisplayStyle) {
            guard style != displayStyle else { return }
            displayStyle = style
            UserDefaults.standard.set(style.rawValue, forKey: trendStyleKey)

            trend.style = style
            if trend.sizeToFitContent() {
                trend.settle(animated: false)
            }
            refresh(force: true)
        }

        func reportDidDismiss() {
            report = nil
            settingsDidDismiss()
        }

        func settingsDidDismiss() {
            guard !isVisible, report == nil else { return }
            window?.isHidden = true
        }

        override func makeWindow() -> DO.OverlayWindow {
            let overlay = DO.OverlayWindow(frame: UIScreen.main.bounds, level: .alert - 1)
            overlay.backgroundColor = .clear

            let host = UIViewController()
            host.view.backgroundColor = .clear
            overlay.rootViewController = host

            trend.style = displayStyle
            trend.delegate = self
            host.view.addSubview(trend)

            overlay.addNoResponseView(host.view)

            memory.setMetric(memoryMetric)

            frames.onChange = { [weak self] in self?.refresh() }
            cpu.onChange = { [weak self] in self?.refresh() }
            memory.onChange = { [weak self] in self?.refresh() }

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationDidEnterBackground),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )

            startEnabledSources()
            didLayout = false

            DO.PerfBenchmark.run()

            return overlay
        }

        private func nextEnabled(after index: Int) -> Int {
            let order = (0..<DO.PerfTrendPlugin.metricCount).filter { enabled.contains($0) }
            guard !order.isEmpty else { return 0 }
            guard let position = order.firstIndex(of: index) else { return order[0] }
            return order[(position + 1) % order.count]
        }

        private func startEnabledSources() {
            for index in enabled {
                startSource(index)
            }
        }

        private func startSource(_ index: Int) {
            switch index {
            case 0: frames.start()
            case 1: cpu.start()
            case 2: memory.start()
            default: break
            }
        }

        private func stopSource(_ index: Int) {
            switch index {
            case 0: frames.stop()
            case 1: cpu.stop()
            case 2: memory.stop()
            default: break
            }
        }

        @objc private func applicationDidEnterBackground() {
            for index in 0..<DO.PerfTrendPlugin.metricCount { stopSource(index) }
        }

        @objc private func applicationWillEnterForeground() {
            startEnabledSources()
        }

        private func layoutTrend() {
            guard let host = window?.rootViewController else { return }

            let size = trend.sizeThatFits(host.view.bounds.size)
            let saved = UserDefaults.standard.object(forKey: DO.PerfTrendView.frameKey) as? [String: CGFloat]

            let fallback = CGPoint(x: host.view.bounds.width - size.width - 12, y: 60)
            let origin = saved.map { CGPoint(x: $0["x"] ?? fallback.x, y: $0["y"] ?? fallback.y) } ?? fallback

            trend.frame = CGRect(origin: origin, size: size)
            trend.settle(animated: false)
            didLayout = true
        }

        private func refresh(force: Bool = false) {
            guard isVisible else {
                trend.isHidden = true
                return
            }

            let now = CACurrentMediaTime()
            let minimum: TimeInterval = (displayStyle == .text) ? 1 : 0.1
            guard force || now - lastRefresh >= minimum else { return }
            lastRefresh = now

            trend.isHidden = false
            trend.render(current: chart(at: currentIndex), all: charts, now: now)

            if !trend.isDragging, trend.sizeToFitContent() {
                trend.settle(animated: false)
            }
        }
    }

}

extension DO.PerfTrendPlugin: DO.PerfTrendViewDelegate {

    func perfTrendViewDidTap(_ view: DO.PerfTrendView) {
        guard displayStyle == .line else { return }
        currentIndex = nextEnabled(after: currentIndex)
        refresh(force: true)
    }

    func perfTrendViewDidLongPress(_ view: DO.PerfTrendView) {
        show()
    }
}
