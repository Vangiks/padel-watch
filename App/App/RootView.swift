import SwiftUI

struct RootView: View {
    @State private var coordinator = AppCoordinator()

    var body: some View {
        switch coordinator.screen {
        case .setup:
            SetupFlowView(
                resumable: coordinator.resumable,
                onResume: { coordinator.resume() },
                onStart: { coordinator.start($0) }
            )
        case .match(let vm):
            ScoreView(vm: vm, onNewMatch: { coordinator.newMatch() })
        }
    }
}
