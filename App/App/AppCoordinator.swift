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
    var resumable: MatchRecord?

    private let store = MatchStore.shared
    private let history = HistoryStore.shared

    init() {
        if let saved = store.load() {
            if saved.state.isFinished {
                // Матч завершился, но приложение закрыли до перехода в Историю —
                // дописываем (идемпотентно) и чистим текущий.
                history.commit(saved.ended())
                store.clear()
            } else {
                resumable = saved
            }
        }
    }

    func start(_ settings: MatchSettings) {
        resumable = nil
        screen = .match(MatchViewModel(settings: settings))
    }

    func resume() {
        guard let saved = resumable else { return }
        resumable = nil
        screen = .match(MatchViewModel(record: saved))
    }

    func newMatch() {
        if case .match(let vm) = screen { vm.commitOnExit() }
        store.clear()
        resumable = nil
        screen = .setup
    }

    /// Полный выход из идущего матча (смах влево → меню → «Выйти»).
    /// Недоигранный матч попадает в Историю как abandoned; завершённый уже там (идемпотентно).
    func exitMatch() {
        if case .match(let vm) = screen { vm.commitOnExit() }
        store.clear()
        resumable = nil
        screen = .setup
    }
}
