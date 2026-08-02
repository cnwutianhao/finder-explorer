import SwiftUI

/// 目录树侧边栏
struct SidebarTreeView: View {
    let roots: [TreeNode]
    let onSelect: (URL) -> Void

    var body: some View {
        List(roots) { node in
            SidebarTreeNodeRow(node: node, onSelect: onSelect)
        }
        .listStyle(.sidebar)
    }
}

struct SidebarTreeNodeRow: View {
    @ObservedObject var node: TreeNode
    let onSelect: (URL) -> Void

    var body: some View {
        if node.children == nil && node.isDirectory {
            // 尚未加载子节点
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.accentColor)
                Text(node.name)
                    .font(.system(size: 13))
                Spacer()

                if node.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 12, height: 12)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelect(node.url) }
            .task {
                await node.loadChildren()
            }
        } else if let children = node.children, !children.isEmpty {
            // 有子文件夹
            DisclosureGroup(
                content: {
                    ForEach(children) { child in
                        SidebarTreeNodeRow(node: child, onSelect: onSelect)
                    }
                },
                label: {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.accentColor)
                        Text(node.name)
                            .font(.system(size: 13))
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(node.url) }
                }
            )
        } else {
            // 空文件夹
            HStack {
                Image(systemName: "folder")
                    .foregroundColor(.secondary)
                Text(node.name)
                    .font(.system(size: 13))
            }
            .contentShape(Rectangle())
            .onTapGesture { onSelect(node.url) }
        }
    }
}
