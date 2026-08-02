import SwiftUI

/// 面包屑地址栏
struct BreadcrumbBar: View {
    @Binding var currentURL: URL
    let onNavigate: (URL) -> Void

    private var pathComponents: [(name: String, url: URL)] {
        var components: [(String, URL)] = []
        var url = currentURL

        // 根目录特殊处理
        if url.path == "/" {
            return [("Macintosh HD", URL(fileURLWithPath: "/"))]
        }

        while url.path != "/" && url.path != "" {
            components.insert((url.lastPathComponent, url), at: 0)
            url = url.deletingLastPathComponent()
        }

        // 添加根
        components.insert(("Macintosh HD", URL(fileURLWithPath: "/")), at: 0)

        return components
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 2)
                    }

                    Button(action: {
                        onNavigate(component.url)
                    }) {
                        Text(component.name)
                            .font(.system(size: 13))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 3)
                            .background(
                                index == pathComponents.count - 1
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear
                            )
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .help(component.url.path)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
