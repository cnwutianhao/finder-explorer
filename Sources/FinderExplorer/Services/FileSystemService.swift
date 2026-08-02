import Foundation
import AppKit

/// 文件系统服务 - 负责读取目录内容
final class FileSystemService {

    /// 读取指定路径下的文件列表（异步）
    func listDirectory(at url: URL, showHidden: Bool = false) throws -> [FileItem] {
        let keys: [URLResourceKey] = [
            .fileSizeKey,
            .contentModificationDateKey,
            .isDirectoryKey,
            .typeIdentifierKey
        ]

        let options: FileManager.DirectoryEnumerationOptions = showHidden
            ? [.skipsSubdirectoryDescendants]
            : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]

        let contents = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: options
        )
        .filter { !$0.lastPathComponent.hasPrefix(".") }

        let dotFiles: [URL]
        if showHidden {
            let all = (try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: .skipsSubdirectoryDescendants)) ?? []
            dotFiles = all.filter { $0.lastPathComponent.hasPrefix(".") }
        } else {
            dotFiles = []
        }

        return (contents + dotFiles)
            .map { FileItem(url: $0) }
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    /// 获取根目录列表
    func listRoots() -> [FileItem] {
        return [
            URL(fileURLWithPath: "/Users/\(NSUserName())"),
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/Users"),
            URL(fileURLWithPath: "/"),
        ].map { FileItem(url: $0) }
    }

    /// 将文件移动到废纸篓
    func moveToTrash(_ urls: [URL]) {
        for url in urls {
            try? FileManager.default.trashItem(at: url, resultingItemURL: nil)
        }
    }

    /// 在 Finder 中显示
    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }

    /// 在 Finder 中打开文件夹
    func openInFinder(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    /// 用默认应用打开文件
    func openFile(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    /// 复制路径到剪贴板
    func copyPath(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)
    }

    /// 新建文件夹
    func createFolder(at url: URL, name: String) throws -> URL {
        let newURL = url.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: false)
        return newURL
    }

    /// 重命名文件或文件夹
    func renameItem(at url: URL, to newName: String) throws -> URL {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try FileManager.default.moveItem(at: url, to: newURL)
        return newURL
    }

    /// 验证文件名是否合法
    func isValidFileName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        let invalidChars = CharacterSet(charactersIn: "/:?!@#$%&*\"'`|\\")
        return name.rangeOfCharacter(from: invalidChars) == nil && name != "." && name != ".."
    }
}
