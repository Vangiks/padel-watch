import SwiftUI
import ScoringEngine

/// Список сыгранных матчей (новые сверху). Тап → детальный экран. Свайп влево → удалить.
struct HistoryListView: View {
    @State private var records: [MatchRecord] = []
    private let store = HistoryStore.shared

    var body: some View {
        List {
            if records.isEmpty {
                Text("Пока нет матчей")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records) { record in
                    NavigationLink {
                        HistoryDetailView(record: record)
                    } label: {
                        HistoryRow(record: record)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("История")
        .onAppear { records = store.list() }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { store.delete(records[index]) }
        records.remove(atOffsets: offsets)
    }
}

/// Строка списка: дата + формат + итог/счёт, с бейджем «не завершён» для брошенных.
private struct HistoryRow: View {
    let record: MatchRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(matchOutcomeTitle(record))
                    .font(.caption).bold()
                Spacer(minLength: 4)
                Text(matchScoreLine(record))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(formattedMatchDate(record.sortDate))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(record.engine.settings.formatLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Общие подписи Истории

/// Заголовок исхода: победитель / ничья / «не завершён».
func matchOutcomeTitle(_ record: MatchRecord) -> LocalizedStringKey {
    guard record.isCompleted else { return "Не завершён" }
    let s = record.state
    if s.isDraw { return "Ничья" }
    switch s.matchWinner {
    case .you: return "Победа: я"
    case .opponent: return "Победа: противник"
    case nil: return "Не завершён"
    }
}

/// Краткий счёт: по сетам (классика) или финальные очки (турнир).
func matchScoreLine(_ record: MatchRecord) -> String {
    let s = record.state
    if s.kind == .classic {
        let sets = s.completedSets.map { "\($0.you)-\($0.opp)" }.joined(separator: " ")
        // Незавершённая классика без сыгранных сетов — показываем геймы текущего сета.
        return sets.isEmpty ? "\(s.currentGames.you)-\(s.currentGames.opp)" : sets
    } else {
        return "\(s.currentPoints.you):\(s.currentPoints.opp)"
    }
}
