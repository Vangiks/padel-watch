import SwiftUI

struct RootView: View {
    @State private var coordinator = AppCoordinator()
    @State private var settings = AppSettings.shared

    var body: some View {
        content
            // Выбранный в приложении язык применяется ко всем `Text(...)`.
            .environment(\.locale, settings.resolvedLocale)
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
