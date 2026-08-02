import Foundation

/// 排序选项
enum SortOption: String, CaseIterable, Identifiable {
    case name = "名称"
    case size = "大小"
    case kind = "类型"
    case date = "修改日期"

    var id: String { rawValue }
}

/// 排序方向
enum SortDirection: CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String {
        switch self {
        case .ascending: return "asc"
        case .descending: return "desc"
        }
    }

    var symbol: String {
        switch self {
        case .ascending: return "↑"
        case .descending: return "↓"
        }
    }

    mutating func toggle() {
        self = (self == .ascending) ? .descending : .ascending
    }
}
