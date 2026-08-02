import SwiftUI

/// 目录树节点
@MainActor
final class TreeNode: Identifiable, ObservableObject {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool

    @Published var children: [TreeNode]?
    @Published var isLoading = false

    init(url: URL, name: String? = nil, isDirectory: Bool = true) {
        self.url = url
        self.name = name ?? url.lastPathComponent
        self.isDirectory = isDirectory
    }

    func loadChildren() async {
        guard isDirectory, children == nil, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        let keys: [URLResourceKey] = [.isDirectoryKey]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            children = []
            return
        }

        children = contents
            .filter { !$0.lastPathComponent.hasPrefix(".") }
            .compactMap { url in
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                return TreeNode(url: url, isDirectory: isDir)
            }
            .filter { $0.isDirectory }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
