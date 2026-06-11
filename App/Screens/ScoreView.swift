import SwiftUI
import ScoringEngine

/// Боевой экран счёта: верхняя строка статуса, две крупные зоны-тапа (лево=ты, право=соперник),
/// нижний ряд кнопок (undo · пауза · redo). При завершении — экран итога.
struct ScoreView: View {
    let vm: MatchViewModel
    let onNewMatch: () -> Void

    var body: some View {
        if vm.state.isFinished {
            MatchEndView(state: vm.state, onNewMatch: onNewMatch)
        } else {
            scoringScreen
                .overlay { if vm.isPaused { pauseOverlay } }
        }
    }

    // MARK: Экран начисления очков

    private var scoringScreen: some View {
        let s = vm.state
        return VStack(spacing: 4) {
            topStrip(s)
            HStack(spacing: 4) {
                teamZone(.you, display: s.youPointDisplay, isServer: s.server == .you, decisive: s.isDecisivePoint)
                teamZone(.opponent, display: s.oppPointDisplay, isServer: s.server == .opponent, decisive: s.isDecisivePoint)
            }
            controlRow
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func topStrip(_ s: MatchState) -> some View {
        if vm.isClassic {
            HStack(spacing: 4) {
                Text("Сеты \(s.setsWon.you)-\(s.setsWon.opp)")
                Spacer(minLength: 2)
                HStack(spacing: 2) {
                    if s.server == .you { Text("🎾") }
                    Text("Геймы \(s.currentGames.you)-\(s.currentGames.opp)")
                    if s.server == .opponent { Text("🎾") }
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 4) {
                if s.server == .you { Text("🎾") }
                Spacer(minLength: 2)
                if let target = vm.tournamentTarget { Text("До \(target)") }
                Spacer(minLength: 2)
                if s.server == .opponent { Text("🎾") }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func teamZone(_ team: Team, display: PointDisplay, isServer: Bool, decisive: Bool) -> some View {
        Button {
            vm.point(team)
        } label: {
            VStack(spacing: 2) {
                Text(display.text)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(decisive ? Color.yellow : Color.primary)
                Text(team.shortName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .background(
            (decisive ? Color.yellow.opacity(0.18) : Color.gray.opacity(0.15)),
            in: RoundedRectangle(cornerRadius: 8)
        )
    }

    private var controlRow: some View {
        HStack(spacing: 18) {
            Button { vm.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                .disabled(!vm.canUndo)
            Button { vm.togglePause() } label: {
                Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
            }
            Button { vm.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                .disabled(!vm.canRedo)
        }
        .buttonStyle(.plain)
        .font(.title3)
    }

    private var pauseOverlay: some View {
        ZStack {
            Rectangle().fill(.black.opacity(0.6)).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("Пауза").font(.headline)
                Button {
                    vm.togglePause()
                } label: {
                    Label("Продолжить", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
