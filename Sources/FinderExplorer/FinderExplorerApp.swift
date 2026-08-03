import SwiftUI
import AppKit

/// 关于窗口
struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 8)

            Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                .resizable()
                .frame(width: 80, height: 80)

            Text("FinderExplorer")
                .font(.system(size: 18, weight: .bold))

            Text("版本 \(AppVersion.marketing) (Build \(AppVersion.build))")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Text("一个基于 SwiftUI 的 macOS 文件管理器，\n支持面包屑导航、树形侧边栏、多选和键盘操作。")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text("需 macOS 14.0 或更高版本")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Link("Tyhoo Wu",
                     destination: URL(string: "https://github.com/cnwutianhao")!)
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor)
                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Link("项目主页",
                     destination: URL(string: "https://github.com/cnwutianhao/finder-explorer")!)
                    .font(.system(size: 10))
                    .foregroundColor(.accentColor)
            }

            Spacer().frame(height: 8)
        }
        .frame(width: 380, height: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

@main
struct FinderExplorerApp: App {
    @StateObject private var navigationState = NavigationState()
    @State private var currentURL = URL(fileURLWithPath: "/Users/\(NSUserName())")
    @State private var files: [FileItem] = []
    @State private var sortOption: SortOption = .name
    @State private var sortDirection: SortDirection = .ascending
    @State private var selectedURLs: Set<URL> = []

    private let fsService = FileSystemService()

    @State private var aboutWindow: NSWindow?

    private func showAboutWindow() {
        if let existing = aboutWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "关于 FinderExplorer"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: AboutView())
        window.setContentSize(NSSize(width: 380, height: 320))
        window.center()
        window.makeKeyAndOrderFront(nil)
        aboutWindow = window
    }

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
        Window("FinderExplorer — 文件管理器 v\(AppVersion.marketing)", id: "main") {
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
            CommandGroup(replacing: .appInfo) {
                Button("关于 FinderExplorer") {
                    showAboutWindow()
                }
            }

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
