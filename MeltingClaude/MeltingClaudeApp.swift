import SwiftUI
import AppKit

@main
struct MeltingClaudeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var vm = UsageViewModel()
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(vm: vm)
        } label: {
            // 아이콘만 표시 (텍스트 없음). 해당 tier 아이콘 없으면 over 폴백.
            Image(vm.menuBarAssetName)
        }
        .menuBarExtraStyle(.window)

        // Cmd+, 또는 Settings 버튼으로 별도 창 열림
        Settings {
            SettingsView(settings: settings)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = AppSettings.shared
        // Sandbox 환경에서 onboarded 였어도 bookmark 가 사라졌으면 다시 폴더 권한 받아야 함.
        if settings.hasOnboarded && FolderAccessStore.shared.hasBookmark {
            ClaudeLogIngestor.shared.startWatching()
        } else {
            showOnboarding()
        }
    }

    private func showOnboarding() {
        let view = OnboardingView(
            settings: AppSettings.shared,
            ingestor: ClaudeLogIngestor.shared,
            onFinish: { [weak self] in
                self?.closeOnboarding()
            }
        )
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to MeltingClaude"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.onboardingWindow = window
    }

    private func closeOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
        ClaudeLogIngestor.shared.startWatching()
    }
}
