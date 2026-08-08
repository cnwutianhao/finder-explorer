import SwiftUI
import AppKit

/// 文件列表 + 列排序 + 右键菜单 + 键盘导航
struct FileListView: View {
    @Binding var files: [FileItem]
    @Binding var sortOption: SortOption
    @Binding var sortDirection: SortDirection
    @Binding var selectedURLs: Set<URL>
    @Binding var clipboardURLs: [URL]
    @Binding var clipboardIsCut: Bool
    @Binding var currentURL: URL
    @Binding var showHiddenFiles: Bool
    let onNavigate: (URL) -> Void
    let fsService: FileSystemService
    @Binding var isRenaming: Bool
    @Binding var renameTarget: URL?
    @Binding var renameText: String
    var renameFieldFocused: FocusState<Bool>.Binding
    let onRefresh: () -> Void

    @State private var focusedRowIndex: Int? = nil
    @State private var isCreatingFolder = false
    @State private var newFolderText = "新建文件夹"
    @FocusState private var newFolderFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 新文件夹输入行（全局）
            if isCreatingFolder {
                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.plus")
                            .resizable().frame(width: 20, height: 16)
                            .foregroundColor(.accentColor)
                        TextField("新建文件夹名称", text: $newFolderText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .focused($newFolderFieldFocused)
                            .onSubmit { commitCreateFolder() }
                            .onExitCommand { isCreatingFolder = false }
                            .onAppear {
                                newFolderText = "新建文件夹"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    newFolderFieldFocused = true
                                }
                            }
                    }
                    .frame(minWidth: 200, alignment: .leading)
                    .padding(.leading, 36)
                    Spacer()
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .background(Color.accentColor.opacity(0.08))
                Divider()
            }

            // 列标题
            HeaderRow(
                sortOption: $sortOption,
                sortDirection: $sortDirection
            )

            Divider()

            // 文件列表
            if files.isEmpty && !isCreatingFolder {
                VStack {
                    Spacer()
                    Text("此文件夹为空")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contextMenu { blankAreaContextMenu }
            } else {
                VStack {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(Array(sortedFiles.enumerated()), id: \.element.id) { index, file in
                                    VStack(spacing: 0) {
                                        if isRenaming && renameTarget == file.url {
                                            renameInlineRow(file: file)
                                        } else {
                                            FileRow(
                                                file: file,
                                                isSelected: selectedURLs.contains(file.url),
                                                isFocused: focusedRowIndex == index,
                                                isCut: clipboardIsCut && clipboardURLs.contains(file.url),
                                                onDoubleClick: {
                                                    if file.isDirectory { onNavigate(file.url) }
                                                    else { fsService.openFile(file.url) }
                                                },
                                                onClick: { handleClick(file, index: index) }
                                            )
                                            .contextMenu { contextMenu(for: file) }
                                        }
                                    }
                                    .background(
                                        selectedURLs.contains(file.url)
                                            ? Color.accentColor.opacity(0.3)
                                            : (focusedRowIndex == index ? Color.accentColor.opacity(0.08) : Color.clear)
                                    )
                                    .contentShape(Rectangle())

                                    Divider().padding(.leading, 28)
                                }
                            }
                        }
                        .contextMenu { blankAreaContextMenu }
                        .onTapGesture { selectedURLs = []; focusedRowIndex = nil }
                    }
                }
                .onAppear { installKeyboardMonitor() }
            }
        }
    }

    // MARK: - 内联重命名行

    private func renameInlineRow(file: FileItem) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(nsImage: iconForFile(file))
                    .resizable().frame(width: 20, height: 20)
                TextField("", text: $renameText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused(renameFieldFocused)
                    .onSubmit { commitRename() }
                    .onExitCommand { cancelRename() }
                    .onAppear {
                        renameText = file.name
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            renameFieldFocused.wrappedValue = true
                        }
                    }
            }
            .frame(minWidth: 200, alignment: .leading)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.accentColor.opacity(0.12))
    }

    private func iconForFile(_ file: FileItem) -> NSImage {
        let icon = NSWorkspace.shared.icon(forFile: file.url.path)
        icon.size = NSSize(width: 20, height: 20)
        return icon
    }

    // MARK: - 排序

    private var sortedFiles: [FileItem] {
        let dirs = files.filter(\.isDirectory)
        let nonDirs = files.filter { !$0.isDirectory }
        let sortedDirs: [FileItem]
        let sortedFiles: [FileItem]

        switch sortOption {
        case .name:
            sortedDirs = dirs.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            sortedFiles = nonDirs.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .size:
            sortedDirs = dirs
            sortedFiles = nonDirs.sorted { ($0.size ?? 0) < ($1.size ?? 0) }
        case .kind:
            sortedDirs = dirs.sorted { $0.fileExtension.localizedStandardCompare($1.fileExtension) == .orderedAscending }
            sortedFiles = nonDirs.sorted { $0.fileExtension.localizedStandardCompare($1.fileExtension) == .orderedAscending }
        case .date:
            sortedDirs = dirs.sorted { ($0.modificationDate ?? .distantPast) < ($1.modificationDate ?? .distantPast) }
            sortedFiles = nonDirs.sorted { ($0.modificationDate ?? .distantPast) < ($1.modificationDate ?? .distantPast) }
        }

        let result = sortDirection == .ascending
            ? (sortedDirs + sortedFiles)
            : (Array(sortedDirs.reversed()) + Array(sortedFiles.reversed()))
        return result
    }

    // MARK: - 点击

    private func handleClick(_ file: FileItem, index: Int) {
        if NSEvent.modifierFlags.contains(.command) {
            if selectedURLs.contains(file.url) {
                selectedURLs.remove(file.url)
            } else {
                selectedURLs.insert(file.url)
            }
        } else if NSEvent.modifierFlags.contains(.shift) {
            selectedURLs.insert(file.url)
        } else {
            selectedURLs = [file.url]
        }
        focusedRowIndex = index
    }

    // MARK: - 键盘事件监控

    @State private var keyboardInstalled = false

    private func handleKey(event: NSEvent) -> NSEvent? {
        guard !isRenaming, !isCreatingFolder,
              let window = NSApp.keyWindow,
              event.window == window else { return event }
        let list = sortedFiles
        guard !list.isEmpty else { return event }

        switch event.keyCode {
        case 125: // 下箭头
            if let idx = focusedRowIndex, idx < list.count - 1 {
                focusedRowIndex = idx + 1
                if !event.modifierFlags.contains(.shift) { selectedURLs = [list[focusedRowIndex!].url] }
                else { selectedURLs.insert(list[focusedRowIndex!].url) }
            } else if focusedRowIndex == nil {
                focusedRowIndex = 0
                selectedURLs = [list[0].url]
            }
            return nil
        case 126: // 上箭头
            if let idx = focusedRowIndex, idx > 0 {
                focusedRowIndex = idx - 1
                if !event.modifierFlags.contains(.shift) { selectedURLs = [list[focusedRowIndex!].url] }
                else { selectedURLs.insert(list[focusedRowIndex!].url) }
            }
            return nil
        case 36: // 回车
            if let idx = focusedRowIndex {
                let file = list[idx]
                if file.isDirectory { onNavigate(file.url) }
                else { fsService.openFile(file.url) }
            }
            return nil
        case 51: // Backspace
            let parent = currentURL.deletingLastPathComponent()
            onNavigate(parent)
            return nil
        case 120: // F2
            if let url = selectedURLs.first, selectedURLs.count == 1 {
                renameTarget = url
                renameText = url.lastPathComponent
                isRenaming = true
            }
            return nil
        default:
            return event
        }
    }

    func installKeyboardMonitor() {
        guard !keyboardInstalled else { return }
        keyboardInstalled = true
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: handleKey)
    }

    /// 开始重命名（从右键菜单或键盘触发）
    func startRename() {
        guard let url = selectedURLs.first, selectedURLs.count == 1 else { return }
        renameTarget = url
        renameText = url.lastPathComponent
        isRenaming = true
    }

    private func commitRename() {
        guard let target = renameTarget,
              !renameText.trimmingCharacters(in: .whitespaces).isEmpty,
              fsService.isValidFileName(renameText),
              renameText != target.lastPathComponent else {
            cancelRename()
            return
        }
        do {
            _ = try fsService.renameItem(at: target, to: renameText.trimmingCharacters(in: .whitespaces))
            onRefresh()
        } catch {
            print("重命名失败: \(error)")
        }
        cancelRename()
    }

    private func cancelRename() {
        isRenaming = false
        renameTarget = nil
        renameText = ""
    }

    func startCreateFolder() {
        isCreatingFolder = true
        newFolderText = "新建文件夹"
    }

    private func commitCreateFolder() {
        guard !newFolderText.trimmingCharacters(in: .whitespaces).isEmpty,
              fsService.isValidFileName(newFolderText) else {
            isCreatingFolder = false
            return
        }
        do {
            _ = try fsService.createFolder(at: currentURL, name: newFolderText.trimmingCharacters(in: .whitespaces))
            onRefresh()
        } catch {
            print("创建文件夹失败: \(error)")
        }
        isCreatingFolder = false
    }

    // MARK: - 菜单

    @ViewBuilder
    private var blankAreaContextMenu: some View {
        Button("新建文件夹") {
            startCreateFolder()
        }

        Button("粘贴") {
            guard !clipboardURLs.isEmpty else { return }
            let executed = fsService.pasteItems(clipboardURLs, to: currentURL, isCut: clipboardIsCut)
            if clipboardIsCut && executed {
                clipboardURLs = []
                clipboardIsCut = false
            }
            onRefresh()
        }
        .disabled(clipboardURLs.isEmpty)

        Divider()

        Button(showHiddenFiles ? "不显示隐藏项目" : "显示隐藏项目") {
            showHiddenFiles.toggle()
        }
    }

    @ViewBuilder
    private func contextMenu(for file: FileItem) -> some View {
        Button("打开") {
            if file.isDirectory { onNavigate(file.url) } else { fsService.openFile(file.url) }
        }

        Divider()

        Button("复制") {
            clipboardURLs = selectedURLs.isEmpty ? [file.url] : Array(selectedURLs)
            clipboardIsCut = false
        }

        Button("剪切") {
            clipboardURLs = selectedURLs.isEmpty ? [file.url] : Array(selectedURLs)
            clipboardIsCut = true
        }

        Divider()

        Button("重命名") {
            renameTarget = file.url
            renameText = file.name
            isRenaming = true
        }

        Divider()

        Button("在 Finder 中显示") {
            fsService.revealInFinder(file.url)
        }

        if file.isDirectory {
            Button("在 Finder 中打开") {
                fsService.openInFinder(file.url)
            }
        }

        Divider()

        Button("复制路径") {
            fsService.copyPath(file.url)
        }

        Divider()

        Button("移到废纸篓") {
            let urls = selectedURLs.isEmpty ? [file.url] : Array(selectedURLs)
            fsService.moveToTrash(urls)
            onRefresh()
        }
        .keyboardShortcut(.delete, modifiers: [])
    }
}

// MARK: - 列标题行

struct HeaderRow: View {
    @Binding var sortOption: SortOption
    @Binding var sortDirection: SortDirection

    var body: some View {
        HStack(spacing: 0) {
            HeaderCell(title: "名称", option: .name, sortOption: $sortOption, sortDirection: $sortDirection)
                .frame(minWidth: 200)
            Divider().frame(height: 20)
            HeaderCell(title: "修改日期", option: .date, sortOption: $sortOption, sortDirection: $sortDirection)
                .frame(width: 155)
            Divider().frame(height: 20)
            HeaderCell(title: "类型", option: .kind, sortOption: $sortOption, sortDirection: $sortDirection)
                .frame(width: 130)
            Divider().frame(height: 20)
            HeaderCell(title: "大小", option: .size, sortOption: $sortOption, sortDirection: $sortDirection)
                .frame(width: 100)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct HeaderCell: View {
    let title: String
    let option: SortOption
    @Binding var sortOption: SortOption
    @Binding var sortDirection: SortDirection

    var body: some View {
        Button(action: {
            if sortOption == option { sortDirection.toggle() }
            else { sortOption = option; sortDirection = .ascending }
        }) {
            HStack(spacing: 4) {
                Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.primary)
                if sortOption == option {
                    Text(sortDirection.symbol).font(.system(size: 10)).foregroundColor(.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 单行文件

struct FileRow: View {
    let file: FileItem
    let isSelected: Bool
    let isFocused: Bool
    let isCut: Bool
    let onDoubleClick: () -> Void
    let onClick: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(nsImage: icon)
                    .resizable().frame(width: 20, height: 20)
                Text(file.name)
                    .font(.system(size: 13)).lineLimit(1)
            }
            .frame(minWidth: 200, alignment: .leading)

            Text(file.formattedDate)
                .font(.system(size: 12)).foregroundColor(.secondary)
                .frame(width: 155, alignment: .leading).padding(.leading, 12)

            Text(file.fileTypeDisplay)
                .font(.system(size: 12)).foregroundColor(.secondary)
                .frame(width: 130, alignment: .leading).padding(.leading, 12)

            Text(file.isDirectory ? "--" : file.formattedSize)
                .font(.system(size: 12)).foregroundColor(.secondary)
                .frame(width: 100, alignment: .trailing).padding(.trailing, 20)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .opacity(isCut ? 0.45 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onDoubleClick() }
        .onTapGesture(count: 1) { onClick() }
    }

    private var icon: NSImage {
        let i = NSWorkspace.shared.icon(forFile: file.url.path)
        i.size = NSSize(width: 20, height: 20)
        return i
    }
}
