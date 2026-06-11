import Foundation
import Observation
import ScoringEngine

/// Модель идущего матча: оборачивает `ScoringEngine`, прокидывает действия в UI
/// и персистит журнал после каждого изменения.
@MainActor
@Observable
final class MatchViewModel {
    private(set) var engine: ScoringEngine
    var isPaused = false

    private let store: MatchStore

    init(engine: ScoringEngine, store: MatchStore = .shared) {
        self.engine = engine
        self.store = store
    }

    convenience init(settings: MatchSettings, store: MatchStore = .shared) {
        self.init(engine: ScoringEngine(settings: settings), store: store)
        store.save(engine)
    }

    var state: MatchState { engine.state }
    var canUndo: Bool { engine.canUndo }
    var canRedo: Bool { engine.canRedo }

    var isClassic: Bool {
        if case .classic = engine.settings.format { return true }
        return false
    }

    var tournamentTarget: Int? {
        if case .tournament(let config) = engine.settings.format { return config.totalPoints }
        return nil
    }

    func point(_ team: Team) {
        guard !isPaused, !state.isFinished else { return }
        engine.pointWon(by: team)
        store.save(engine)
    }

    func undo() {
        engine.undo()
        store.save(engine)
    }

    func redo() {
        engine.redo()
        store.save(engine)
    }

    func togglePause() { isPaused.toggle() }
}
