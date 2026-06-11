import Foundation
import Observation
import ScoringEngine

/// Модель идущего матча: оборачивает `ScoringEngine`, прокидывает действия в UI,
/// персистит журнал после каждого изменения и управляет workout-сессией HealthKit.
@MainActor
@Observable
final class MatchViewModel {
    private(set) var engine: ScoringEngine
    var isPaused = false
    private(set) var summary: WorkoutSummary?

    private let store: MatchStore
    #if os(watchOS)
    let workout = WorkoutManager()
    #endif

    init(engine: ScoringEngine, store: MatchStore = .shared) {
        self.engine = engine
        self.store = store
        startWorkout()
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
        if state.isFinished { finishWorkout() }
    }

    func undo() {
        engine.undo()
        store.save(engine)
    }

    func redo() {
        engine.redo()
        store.save(engine)
    }

    func togglePause() {
        isPaused.toggle()
        #if os(watchOS)
        if isPaused { workout.pause() } else { workout.resume() }
        #endif
    }

    // MARK: Workout

    private func startWorkout() {
        #if os(watchOS)
        guard !state.isFinished else { return }
        Task {
            await workout.requestAuthorization()
            workout.start()
        }
        #endif
    }

    private func finishWorkout() {
        #if os(watchOS)
        Task { self.summary = await workout.end() }
        #endif
    }
}
