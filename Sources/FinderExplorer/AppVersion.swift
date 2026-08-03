import Foundation

/// 应用版本号 — 唯一版本定义点
enum AppVersion {
    /// 对外展示版本 (SemVer)，对应 CFBundleShortVersionString
    static let marketing = "1.0.0"
    /// 内部构建号，对应 CFBundleVersion
    static let build = "1"
}
