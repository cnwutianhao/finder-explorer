import SwiftUI

/// 面包屑地址栏 — 点击空白区域切换为可编辑路径，支持选中复制
struct BreadcrumbBar: View {
    @Binding var currentURL: URL
    let onNavigate: (URL) -> Void

    @State private var isEditing = false
    @State private var editPath = ""
    @FocusState private var isFocused: Bool
    @State private var escMonitorInstalled = false

    private var pathComponents: [(name: String, url: URL)] {
        var components: [(String, URL)] = []
        var url = currentURL

        if url.path == "/" {
            return [("Macintosh HD", URL(fileURLWithPath: "/"))]
        }

        while url.path != "/" && url.path != "" {
            components.insert((url.lastPathComponent, url), at: 0)
            url = url.deletingLastPathComponent()
        }

        components.insert(("Macintosh HD", URL(fileURLWithPath: "/")), at: 0)

        return components
    }

    var body: some View {
        ZStack {
            if isEditing {
                editField
            } else {
                breadcrumbView
            }
        }
        .frame(height: 28)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - 编辑模式

    private var editField: some View {
        HStack(spacing: 6) {
            Image(systemName: "folder")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            TextField("输入路径", text: $editPath)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFocused)
                .onSubmit { commitEdit() }
                .onAppear {
                    editPath = currentURL.path
                    isFocused = true
                    installEscMonitor()
                    // 自动全选文本，方便复制
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                    }
                }
            Button {
                cancelEdit()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("取消 (Esc)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private func installEscMonitor() {
        guard !escMonitorInstalled else { return }
        escMonitorInstalled = true
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC
                cancelEdit()
                return nil
            }
            return event
        }
    }

    private func commitEdit() {
        let path = editPath.trimmingCharacters(in: .whitespaces)
        guard !path.isEmpty else { cancelEdit(); return }
        let url = URL(fileURLWithPath: path)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
            onNavigate(url)
        }
        cancelEdit()
    }

    private func cancelEdit() {
        isEditing = false
        editPath = ""
        escMonitorInstalled = false
    }

    // MARK: - 面包屑模式

    private var breadcrumbView: some View {
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
        .contentShape(Rectangle())
        .onTapGesture { startEdit() }
    }

    private func startEdit() {
        editPath = currentURL.path
        escMonitorInstalled = false
        isEditing = true
    }
}
