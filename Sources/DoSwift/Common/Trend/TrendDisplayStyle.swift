//
//  TrendDisplayStyle.swift
//  DoSwift
//

/// 同一条数据序列的两种展示形式。
///
/// 它们的差别**全部在 UI 层**：一次画几条、要用多大的时间窗口、多久刷新一次。
/// 数据层（采样 + 序列）对此一无所知——这正是二者能并存的理由。
enum TrendDisplayStyle: String, CaseIterable {

    /// 一次一条，带 30 秒曲线
    case line

    /// 一次全部，一行文字
    case text

    var title: String {
        switch self {
        case .line: return "折线图"
        case .text: return "单行文字"
        }
    }
}
