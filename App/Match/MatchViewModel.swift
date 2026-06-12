import Foundation
import Observation
import ScoringEngine

/// Модель идущего матча: оборачивает `ScoringEngine`, прокидывает действия в UI,
/// персистит текущий матч после каждого изменения, управляет workout-сессией HealthKit
/// и коммитит матч в Историю при завершении/выходе.
@MainActor
@Observable
final class MatchViewModel {
    private(set) var engine: ScoringEngine
    var isPaused = false
    private(set) var summary: WorkoutSummary?

    /// Идентичность матча — живёт с момента старта, переживает резюм, едет в Историю.
    private let id: UUID
    private let startedAt: Date
    private var endedAt: Date?

    private let store: MatchStore
    private let history: HistoryStore
    #if os(watchOS)
    let workout = WorkoutManager()
    #endif

    /// Создать VM из записи (новый матч или резюм незавершённого).
    init(record: MatchRecord, store: MatchStore = .shared, history: HistoryStore = .shared) {
        self.engine = record.engine
        self.id = record.id
        self.startedAt = record.startedAt
        self.endedAt = record.endedAt
        self.summary = record.workout
        self.store = store
        self.history = history
        startWorkout()
    }

    /// Новый матч из настроек.
    convenience init(settings: MatchSettings, store: MatchStore = .shared, history: HistoryStore = .shared) {
        self.init(record: MatchRecord(engine: ScoringEngine(settings: settings)), store: store, history: history)
        persistCurrent()
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
        if state.isFinished {
            // Коммит сразу (workout ещё догружается); сводку дозапишем по приходу.
            endedAt = Date()
            commitToHistory()
            finishWorkout()
        }
        persistCurrent()
    }

    func undo() {
        engine.undo()
        persistCurrent()
    }

    func redo() {
        engine.redo()
        persistCurrent()
    }

    func togglePause() {
        isPaused.toggle()
        #if os(watchOS)
        if isPaused { workout.pause() } else { workout.resume() }
        #endif
    }

    /// Зафиксировать матч в Истории при уходе с экрана (через «Выйти» или «Новый матч»).
    /// Завершённый матч уже закоммичен на финише — повтор идемпотентен; недоигранный пишется как abandoned.
    func commitOnExit() {
        if endedAt == nil { endedAt = Date() }
        commitToHistory()
        stopWorkout()
    }

    // MARK: Персистентность

    private func currentRecord(ended: Bool) -> MatchRecord {
        MatchRecord(
            id: id,
            startedAt: startedAt,
            endedAt: ended ? (endedAt ?? Date()) : endedAt,
            engine: engine,
            workout: summary
        )
    }

    private func persistCurrent() {
        store.save(currentRecord(ended: false))
    }

    private func commitToHistory() {
        history.commit(currentRecord(ended: true))
    }

    // MARK: Workout

    private func startWorkout() {
        #if os(watchOS)
        guard AppSettings.shared.trackActivity, !state.isFinished else { return }
        Task {
            await workout.requestAuthorization()
            workout.start()
        }
        #endif
    }

    private func finishWorkout() {
        #if os(watchOS)
        Task {
            self.summary = await workout.end()
            // Дозаписываем сводку в уже созданную запись Истории (тот же id) и в текущий матч.
            self.commitToHistory()
            self.persistCurrent()
        }
        #endif
    }

    /// Завершить workout-сессию при досрочном выходе из матча.
    func stopWorkout() {
        #if os(watchOS)
        Task { _ = await workout.end() }
        #endif
    }
}
