import Foundation

/// 导航状态管理 — 前进/后退历史
@MainActor
final class NavigationState: ObservableObject {

    private var backStack: [URL] = []
    private var forwardStack: [URL] = []

    func push(_ url: URL) {
        backStack.append(url)
        forwardStack.removeAll()
    }

    func goBack(from current: URL) -> URL? {
        guard !backStack.isEmpty else { return nil }
        forwardStack.append(current)
        let previous = backStack.removeLast()
        return previous
    }

    func goForward(from current: URL) -> URL? {
        guard !forwardStack.isEmpty else { return nil }
        backStack.append(current)
        let next = forwardStack.removeLast()
        return next
    }

    func canGoBack() -> Bool { !backStack.isEmpty }
    func canGoForward() -> Bool { !forwardStack.isEmpty }

    var backCount: Int { backStack.count }
    var forwardCount: Int { forwardStack.count }
}
