import Foundation
import ScoringEngine

/// Запись матча для Истории и (позже) синхронизации с бэкендом.
///
/// Обёртка над *чистым* `ScoringEngine`: добавляет идентичность, даты и сводку тренировки,
/// о которых сам движок ничего не знает (он переиспользуется в TS-вебе как есть).
///
/// Тот же тип лежит в `current-match.json` по ходу матча (активный: `endedAt == nil`)
/// и копируется в `history/` при завершении/выходе. `id` генерируется при старте матча —
/// это даёт идемпотентный коммит и дедуп при будущем синке.
///
/// Статус (completed/abandoned) отдельным полем не храним — он производный от журнала
/// (`isCompleted == state.isFinished`). См. ADR `docs/adr/0001-match-history-storage.md`.
struct MatchRecord: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    /// Момент ухода матча из активной игры (финиш по правилам или досрочный выход). `nil` — матч ещё идёт.
    var endedAt: Date?
    var engine: ScoringEngine
    /// Сводка тренировки. Может быть `nil` (workout не запускался / не успел догрузиться / нет доступа).
    var workout: WorkoutSummary?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        engine: ScoringEngine,
        workout: WorkoutSummary? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.engine = engine
        self.workout = workout
    }

    /// Производное состояние счёта.
    var state: MatchState { engine.state }

    /// Доведён ли матч до итога по правилам (иначе — abandoned).
    var isCompleted: Bool { engine.state.isFinished }

    /// Ключ сортировки/именования файла: когда матч закончился (или, для активного, когда начался).
    var sortDate: Date { endedAt ?? startedAt }

    /// Копия с проставленным `endedAt` (если ещё не стоял).
    func ended(at date: Date = Date()) -> MatchRecord {
        var copy = self
        if copy.endedAt == nil { copy.endedAt = date }
        return copy
    }
}

// Идентичность по `id` — для навигации и дедупа (журнал/движок не Hashable).
extension MatchRecord: Hashable {
    static func == (lhs: MatchRecord, rhs: MatchRecord) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
