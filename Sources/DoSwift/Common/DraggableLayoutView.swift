//
//  DraggableLayoutView.swift
//  DoSwift
//
//  Created by Claude Code on 2026/09/30.
//  Copyright © 2026 DoSwift. All rights reserved.
//

import UIKit

/// 按照规范，如果业务容器内部使用 AutoLayout 布局，需要确保约束满足 self sizing 和一层转换
final class DraggableLayoutView: DraggableView {
    
    /// 被托管的内容视图。大小完全由这里决定，内部排版归它自己。
    let contentView: UIView
    
    init(contentView: UIView) {
        self.contentView = contentView
        super.init(frame: .zero)
        
        addSubview(contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return contentView.systemLayoutSizeFitting(size)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        contentView.frame = bounds
    }
    
}
