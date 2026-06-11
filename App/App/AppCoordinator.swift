import Foundation
import Observation
import ScoringEngine

/// Верхнеуровневая навигация: мастер настройки ↔ экран матча.
/// При запуске проверяет сохранённый незавершённый матч для восстановления.
@MainActor
@Observable
final class AppCoordinator {
    enum Screen {
        case setup
        case match(MatchViewModel)
    }

    var screen: Screen = .setup
    /// Незавершённый матч, доступный для продолжения (если был сохранён).
    var resumable: ScoringEngine?

    private let store = MatchStore.shared

    init() {
        if let saved = store.load(), !saved.state.isFinished {
            resumable = saved
        }
    }

    func start(_ settings: MatchSettings) {
        resumable = nil
        screen = .match(MatchViewModel(settings: settings))
    }

    func resume() {
        guard let saved = resumable else { return }
        resumable = nil
        screen = .match(MatchViewModel(engine: saved))
    }

    func newMatch() {
        if case .match(let vm) = screen { vm.stopWorkout() }
        store.clear()
        resumable = nil
        screen = .setup
    }

    /// Полный выход из идущего матча (смах влево → меню → «Выйти»).
    func exitMatch() {
        if case .match(let vm) = screen { vm.stopWorkout() }
        store.clear()
        resumable = nil
        screen = .setup
    }
}
