import SwiftUI
import ScoringEngine

/// Экран итога матча: победитель/ничья + счёт по сетам (классика) или финальные очки (турнир).
/// Сводка тренировки (длительность/пульс/калории) добавится с интеграцией HealthKit.
struct MatchEndView: View {
    let state: MatchState
    let onNewMatch: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                scoreSummary

                Button(action: onNewMatch) {
                    Label("Новый матч", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var title: String {
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
}
