import SwiftUI
import AppKit

@main
struct FinderExplorerApp: App {
    @StateObject private var navigationState = NavigationState()
    @State private var currentURL = URL(fileURLWithPath: "/Users/\(NSUserName())")
    @State private var files: [FileItem] = []
    @State private var sortOption: SortOption = .name
    @State private var sortDirection: SortDirection = .ascending
    @State private var selectedURLs: Set<URL> = []

    private let fsService = FileSystemService()

    private func setAppIcon() {
        guard let bundleURL = Bundle.main.url(forResource: "FinderExplorer_FinderExplorer", withExtension: "bundle"),
              let bundle = Bundle(url: bundleURL) else {
            print("[FinderExplorer] 未找到资源 bundle")
            return
        }
        guard let icnsURL = bundle.url(forResource: "AppIcon", withExtension: "icns") else {
            print("[FinderExplorer] 未找到 AppIcon.icns")
            return
        }
        let icon = NSImage(contentsOf: icnsURL)
        NSApp.applicationIconImage = icon
        print("[FinderExplorer] 图标已设置")
    }

    var body: some Scene {
        Window("FinderExplorer — 文件管理器", id: "main") {
            NavigationSplitView {
                SidebarTreeView(
                    roots: [
                        TreeNode(url: URL(fileURLWithPath: "/Users/\(NSUserName())"), name: "个人目录"),
                        TreeNode(url: URL(fileURLWithPath: "/Applications"), name: "应用程序"),
                        TreeNode(url: URL(fileURLWithPath: "/Users"), name: "用户"),
                        TreeNode(url: URL(fileURLWithPath: "/"), name: "Macintosh HD"),
                    ],
                    onSelect: { url in
                        navigationState.push(currentURL)
                        currentURL = url
                        files = (try? fsService.listDirectory(at: url)) ?? []
                        selectedURLs = []
                    }
                )
                .frame(minWidth: 200)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
            } detail: {
                MainContentView(
                    currentURL: $currentURL,
                    files: $files,
                    sortOption: $sortOption,
                    sortDirection: $sortDirection,
                    selectedURLs: $selectedURLs,
                    navigationState: navigationState,
                    fsService: fsService
                )
            }
            .navigationSplitViewStyle(.balanced)
            .frame(minWidth: 800, minHeight: 500)
            .onAppear {
                setAppIcon()
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                print("[FinderExplorer] 窗口已显示")
            }
        }
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .pasteboard) {
                Button("移到废纸篓") {
                    let urls = selectedURLs.isEmpty ? [] : Array(selectedURLs)
                    fsService.moveToTrash(urls)
                    files = (try? fsService.listDirectory(at: currentURL)) ?? []
                }
                .keyboardShortcut(.delete, modifiers: [])
            }
        }
    }
}
