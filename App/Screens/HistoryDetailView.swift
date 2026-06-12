import SwiftUI
import ScoringEngine

/// Детальный экран матча из Истории: исход + счёт + дата/формат + сводка тренировки.
/// Покадрового реплея пока нет (журнал для него уже хранится в записи).
struct HistoryDetailView: View {
    let record: MatchRecord

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(matchOutcomeTitle(record))
                    .font(.headline)
                    .multilineTextAlignment(.center)

                scoreSummary

                Text(record.engine.settings.formatLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    metric(Text("Дата"), Text(formattedMatchDate(record.sortDate)))
                    if let w = record.workout {
                        metric(Text("Длительность"), Text(formattedDuration(w.duration)))
                        if w.heartRateBPM > 0 {
                            metric(Text("Пульс"), Text("\(Int(w.heartRateBPM)) уд/мин"))
                        }
                        if w.activeEnergyKcal > 0 {
                            metric(Text("Калории"), Text("\(Int(w.activeEnergyKcal)) ккал"))
                        }
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Матч")
    }

    @ViewBuilder
    private var scoreSummary: some View {
        let s = record.state
        if s.kind == .classic {
            HStack(spacing: 6) {
                ForEach(Array(s.completedSets.enumerated()), id: \.offset) { _, set in
                    Text("\(set.you)-\(set.opp)")
                        .font(.title3.monospacedDigit())
                }
                if s.completedSets.isEmpty {
                    Text("\(s.currentGames.you)-\(s.currentGames.opp)")
                        .font(.title3.monospacedDigit())
                }
            }
        } else {
            Text("\(s.currentPoints.you) : \(s.currentPoints.opp)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
        }
    }

    private func metric(_ label: Text, _ value: Text) -> some View {
        HStack {
            label
            Spacer()
            value.foregroundStyle(.primary)
        }
    }
}
