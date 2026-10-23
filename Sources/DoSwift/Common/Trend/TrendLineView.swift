//
//  TrendLineView.swift
//  DoSwift
//

import UIKit

/// 折线形式的卡片内容：**上面一行字，下面一条曲线**，两块各自是独立的 view。
///
/// 拆开的好处是折线区只认自己的 `bounds`（见 `TrendPlotView`），卡片尺寸与内外边距
/// 全部留在这一层。以后换一种图（比如帧率的柱状图）只需要换下面那一块。
///
/// **尺寸固定 112 × 66**，所以不接 Dynamic Type：卡片是按最长的一行内容
/// （「内存 1204 MB」）量出来的，字号变大就会溢出。字号是设计的一部分。
final class TrendLineView: UIView {

    private enum Metrics {
        static let size = CGSize(width: 112, height: 66)
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 10
        static let headerHeight: CGFloat = 20
        static let spacing: CGFloat = 6
        static let plotHeight: CGFloat = 20
    }

    /// 展示窗口的长度，单位秒。**UI 层的旋钮**：决定「一秒走多少像素」，
    /// 和源的采样率无关（横轴按时间戳定位，点稀只是线显得折得硬）。
    var span: TimeInterval = 30

    private let header = TrendHeaderView()
    private let plot = TrendPlotView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        loadViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize { Metrics.size }
    override func sizeThatFits(_ size: CGSize) -> CGSize { Metrics.size }

    func render(_ chart: TrendChart?, now: TimeInterval) {
        header.render(chart, now: now)

        guard let chart = chart else {
            plot.render(nil)
            return
        }
        // 告警只影响颜色：数值照画，红不红是这一层的事，绘制层不认识「告警」
        plot.render(chart.plotContent(
            for: CGSize(
                width: Metrics.size.width - Metrics.horizontalPadding * 2,
                height: Metrics.plotHeight
            ),
            window: (now - span)...now,
            tint: chart.isAlarming(at: now) ? .systemRed : .label
        ))
    }

    private func loadViews() {
        header.translatesAutoresizingMaskIntoConstraints = false
        plot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(header)
        addSubview(plot)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.verticalPadding),
            header.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
            header.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalPadding),
            header.heightAnchor.constraint(equalToConstant: Metrics.headerHeight),

            plot.topAnchor.constraint(equalTo: header.bottomAnchor, constant: Metrics.spacing),
            plot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
            plot.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalPadding),
            plot.heightAnchor.constraint(equalToConstant: Metrics.plotHeight),
        ])
    }
}
