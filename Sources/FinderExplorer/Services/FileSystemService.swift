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

    /// 粘贴（移动或复制），目标已存在同名项时弹窗询问，返回 true 表示剪切已执行（调用方应清空剪贴板）
    @MainActor
    @discardableResult
    func pasteItems(_ urls: [URL], to destination: URL, isCut: Bool) -> Bool {
        let conflictNames = urls.compactMap { url -> String? in
            let dest = destination.appendingPathComponent(url.lastPathComponent)
            return FileManager.default.fileExists(atPath: dest.path) ? url.lastPathComponent : nil
        }

        var replaceNames: Set<String> = []
        var renameConflicts = false
        var skipNames: Set<String> = []

        if !conflictNames.isEmpty {
            let alert = NSAlert()
            alert.messageText = "「\(destination.lastPathComponent)」中已存在同名项目"
            let list = conflictNames.count <= 3
                ? conflictNames.joined(separator: "、")
                : "\(conflictNames.count) 个项目"
            alert.informativeText = "「\(list)」已存在，要如何处理？"
            alert.addButton(withTitle: "替换")
            if isCut {
                alert.addButton(withTitle: "跳过")
                alert.addButton(withTitle: "取消")
            } else {
                alert.addButton(withTitle: "保留两者")
                alert.addButton(withTitle: "跳过")
            }
            alert.buttons[2].keyEquivalent = "\u{1b}" // Esc

            switch alert.runModal() {
            case .alertFirstButtonReturn:
                replaceNames = Set(conflictNames)
            case .alertSecondButtonReturn:
                if isCut {
                    skipNames = Set(conflictNames)
                } else {
                    renameConflicts = true
                }
            default:
                if isCut { return false } // 取消：什么都不做
                skipNames = Set(conflictNames)
            }
        }

        for url in urls {
            let name = url.lastPathComponent
            if skipNames.contains(name) { continue }
            // 剪切到原目录：无意义，跳过
            if isCut && url.deletingLastPathComponent().standardizedFileURL == destination.standardizedFileURL { continue }

            var dest = destination.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: dest.path) {
                if replaceNames.contains(name) {
                    try? FileManager.default.removeItem(at: dest)
                } else if renameConflicts {
                    dest = nextAvailableName(for: url, in: destination)
                } else {
                    continue
                }
            }
            do {
                if isCut {
                    try FileManager.default.moveItem(at: url, to: dest)
                } else {
                    try FileManager.default.copyItem(at: url, to: dest)
                }
            } catch {
                print("粘贴失败 \(name): \(error)")
            }
        }
        return isCut
    }

    /// 生成不冲突的副本名（"xxx 副本"、"xxx 副本 2"...）
    private func nextAvailableName(for url: URL, in destination: URL) -> URL {
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        func name(_ suffix: String) -> String { ext.isEmpty ? "\(base) \(suffix)" : "\(base) \(suffix).\(ext)" }
        var candidate = destination.appendingPathComponent(name("副本"))
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = destination.appendingPathComponent(name("副本 \(n)"))
            n += 1
        }
        return candidate
    }

    /// 验证文件名是否合法
    func isValidFileName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        let invalidChars = CharacterSet(charactersIn: "/:?!@#$%&*\"'`|\\")
        return name.rangeOfCharacter(from: invalidChars) == nil && name != "." && name != ".."
    }
}
