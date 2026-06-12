import SwiftUI

struct RootView: View {
    @State private var coordinator = AppCoordinator()
    @State private var settings = AppSettings.shared
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                SplashView()
                    .transition(.opacity)
            } else {
                content
                    .transition(.opacity)
            }
        }
        // Выбранный в приложении язык применяется ко всем `Text(...)`.
        .environment(\.locale, settings.resolvedLocale)
        .task {
            // Короткая брендовая заставка при запуске.
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            withAnimation(.easeInOut(duration: 0.35)) { isLoading = false }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.screen {
        case .setup:
            SetupFlowView(
                resumable: coordinator.resumable,
                onResume: { coordinator.resume() },
                onStart: { coordinator.start($0) }
            )
        case .match(let vm):
            ScoreView(
                vm: vm,
                onNewMatch: { coordinator.newMatch() },
                onExit: { coordinator.exitMatch() }
            )
        }
    }
}
