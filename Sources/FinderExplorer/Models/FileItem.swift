import Foundation

/// 文件/文件夹的数据模型
struct FileItem: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64?
    let modificationDate: Date?
    let fileExtension: String

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = url.hasDirectoryPath

        let resourceValues = try? url.resourceValues(forKeys: [
            .fileSizeKey,
            .contentModificationDateKey,
            .isDirectoryKey
        ])

        self.size = resourceValues?.fileSize.map(Int64.init)
        self.modificationDate = resourceValues?.contentModificationDate
        self.fileExtension = url.pathExtension
    }

    /// 格式化文件大小
    var formattedSize: String {
        guard let size = size, !isDirectory else { return "--" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    /// 格式化修改日期
    var formattedDate: String {
        guard let date = modificationDate else { return "--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    /// 文件类型描述
    var fileTypeDisplay: String {
        if isDirectory { return "文件夹" }
        if fileExtension.isEmpty { return "文件" }
        return fileExtension.uppercased() + " 文件"
    }

    /// Finder 文件类型标签 (UTI)
    var utiType: String {
        if isDirectory { return "public.folder" }
        return (try? url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier) ?? "public.data"
    }

    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
}
