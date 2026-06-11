import SwiftUI
import ScoringEngine

/// Экран итога матча: победитель/ничья + счёт по сетам (классика) или финальные очки (турнир)
/// + сводка тренировки (длительность/пульс/калории), если workout-сессия завершилась.
struct MatchEndView: View {
    let state: MatchState
    let summary: WorkoutSummary?
    let onNewMatch: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                scoreSummary

                if let summary {
                    workoutSummary(summary)
                }

                Button(action: onNewMatch) {
                    Label("Новый матч", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var title: LocalizedStringKey {
        if state.isDraw { return "Ничья" }
        switch state.matchWinner {
        case .you: return "Победа: ты"
        case .opponent: return "Победа: соперник"
        case nil: return "Матч окончен"
        }
    }

    @ViewBuilder
    private var scoreSummary: some View {
        if state.kind == .classic {
            HStack(spacing: 6) {
                ForEach(Array(state.completedSets.enumerated()), id: \.offset) { _, set in
                    Text("\(set.you)-\(set.opp)")
                        .font(.title3.monospacedDigit())
                }
            }
        } else {
            Text("\(state.currentPoints.you) : \(state.currentPoints.opp)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
        }
    }

    private func workoutSummary(_ s: WorkoutSummary) -> some View {
        VStack(spacing: 4) {
            metric(Text("Длительность"), Text(formattedDuration(s.duration)))
            if s.heartRateBPM > 0 {
                metric(Text("Пульс"), Text("\(Int(s.heartRateBPM)) уд/мин"))
            }
            if s.activeEnergyKcal > 0 {
                metric(Text("Калории"), Text("\(Int(s.activeEnergyKcal)) ккал"))
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func metric(_ label: Text, _ value: Text) -> some View {
        HStack {
            label
            Spacer()
            value.foregroundStyle(.primary)
        }
    }
}
