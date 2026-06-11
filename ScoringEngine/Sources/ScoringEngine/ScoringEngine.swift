import Foundation

/// Движок счёта на основе журнала событий (event-sourcing).
///
/// Хранит только настройки и упорядоченный журнал выигранных очков плюс курсор для undo/redo.
/// Весь видимый счёт (`state`) вычисляется заново из префикса журнала — это даёт надёжный
/// откат на любую глубину и корректную «размотку» переходов гейм/сет/тай-брейк.
///
/// `Codable` — чтобы персистить журнал на диск после каждого очка (авто-восстановление матча)
/// и в будущем синхронизировать с веб-приложением.
public struct ScoringEngine: Codable, Equatable, Sendable {
    public private(set) var settings: MatchSettings
    private var events: [Team]
    private var cursor: Int

    public init(settings: MatchSettings) {
        self.settings = settings
        self.events = []
        self.cursor = 0
    }

    /// Применённые (видимые) очки — журнал до курсора.
    public var appliedPoints: [Team] { Array(events[0..<cursor]) }

    /// Текущее производное состояние матча.
    public var state: MatchState {
        MatchState.compute(settings: settings, points: events[0..<cursor])
    }

    public var canUndo: Bool { cursor > 0 }
    public var canRedo: Bool { cursor < events.count }

    /// Начислить очко команде. После завершённого матча игнорируется.
    /// Новое очко после отката отбрасывает «ветку» redo.
    public mutating func pointWon(by team: Team) {
        guard !state.isFinished else { return }
        if cursor < events.count {
            events.removeSubrange(cursor..<events.count)
        }
        events.append(team)
        cursor += 1
    }

    /// Откатить последнее очко.
    public mutating func undo() {
        guard canUndo else { return }
        cursor -= 1
    }

    /// Повторить откатанное очко.
    public mutating func redo() {
        guard canRedo else { return }
        cursor += 1
    }
}
