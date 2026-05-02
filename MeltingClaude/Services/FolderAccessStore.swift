import Foundation
import AppKit

/// Sandbox 환경에서 사용자가 한 번 선택한 폴더(예: ~/.claude/) 에 대한
/// security-scoped bookmark 를 영속화하고 안전하게 재접근하는 헬퍼.
final class FolderAccessStore {
    static let shared = FolderAccessStore()

    private let bookmarkKey = "claudeFolderBookmark"
    private let d = UserDefaults.standard

    private init() {}

    /// 이전에 사용자가 폴더를 선택해서 bookmark 가 저장돼 있는가.
    var hasBookmark: Bool {
        d.data(forKey: bookmarkKey) != nil
    }

    /// NSOpenPanel 띄워 사용자가 폴더 선택. 성공 시 bookmark 저장 후 URL 반환.
    /// 메인 스레드에서 호출.
    @MainActor
    @discardableResult
    func requestAccess() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.directoryURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
        panel.prompt = "Grant Access"
        panel.title  = "Select your ~/.claude/ folder"
        panel.message = "MeltingClaude needs read access to this folder to parse your local Claude Code session logs. No data leaves your Mac."

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            d.set(bookmark, forKey: bookmarkKey)
            return url
        } catch {
            return nil
        }
    }

    /// 저장된 bookmark 를 URL 로 풀어서 반환. 접근 시작은 별도.
    /// stale 이면 재생성 시도.
    func resolveURL() -> URL? {
        guard let data = d.data(forKey: bookmarkKey) else { return nil }
        var stale = false
        do {
            let url = try URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &stale
            )
            if stale, url.startAccessingSecurityScopedResource() {
                if let fresh = try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                ) {
                    d.set(fresh, forKey: bookmarkKey)
                }
                url.stopAccessingSecurityScopedResource()
            }
            return url
        } catch {
            return nil
        }
    }

    /// 접근 시작 → block 실행 → 자동 stop. block 안에서 읽기/탐색 모두 가능.
    /// bookmark 없거나 접근 시작 실패 시 nil.
    func withAccess<T>(_ body: (URL) throws -> T) rethrows -> T? {
        guard let url = resolveURL() else { return nil }
        let started = url.startAccessingSecurityScopedResource()
        guard started else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }
        return try body(url)
    }

    func clear() {
        d.removeObject(forKey: bookmarkKey)
    }
}
