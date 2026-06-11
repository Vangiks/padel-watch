import SwiftUI
import ScoringEngine

/// Пошаговый мастер настройки матча:
/// Формат → (Классика: deuce → сеты | Турнир: очки N) → первая подача → старт.
struct SetupFlowView: View {
    let resumable: ScoringEngine?
    let onResume: () -> Void
    let onStart: (MatchSettings) -> Void

    private enum Step: Hashable { case deuce, sets, points, server }

    @State private var path: [Step] = []
    @State private var isClassic = true
    @State private var deuce: DeuceMode = .advantage
    @State private var numberOfSets = 1
    @State private var totalPoints = 24

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if let resumable {
                    Section {
                        Button(action: onResume) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Продолжить матч").bold()
                                Text(resumeSubtitle(resumable))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Формат") {
                    Button("Классика") { isClassic = true; path = [.deuce] }
                    Button("Турнир") { isClassic = false; path = [.points] }
                }
            }
            .navigationTitle("Падел")
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .deuce: deuceStep
                case .sets: setsStep
                case .points: pointsStep
                case .server: serverStep
                }
            }
        }
    }

    // MARK: Шаги

    private var deuceStep: some View {
        List {
            ForEach(DeuceMode.presets, id: \.title) { mode in
                Button(mode.title) {
                    deuce = mode
                    path.append(.sets)
                }
            }
        }
        .navigationTitle("Режим ровно")
    }

    private var setsStep: some View {
        List {
            Button("1 сет") { numberOfSets = 1; path.append(.server) }
            Button("3 сета") { numberOfSets = 3; path.append(.server) }
        }
        .navigationTitle("Сеты")
    }

    private var pointsStep: some View {
        VStack(spacing: 8) {
            Text("\(totalPoints)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
            HStack {
                ForEach([16, 24, 32], id: \.self) { preset in
                    Button("\(preset)") { totalPoints = preset }
                        .buttonStyle(.bordered)
                }
            }
            Stepper("Очки до", value: $totalPoints, in: 4...80, step: 2)
                .labelsHidden()
            Button("Далее") { path.append(.server) }
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 6)
        .navigationTitle("Очки")
    }

    private var serverStep: some View {
        List {
            Button("Подаю я") { finish(server: .you) }
            Button("Подаёт соперник") { finish(server: .opponent) }
        }
        .navigationTitle("Первая подача")
    }

    // MARK: Сборка настроек

    private func finish(server: Team) {
        let format: MatchFormat = isClassic
            ? .classic(ClassicConfig(numberOfSets: numberOfSets, deuceMode: deuce))
            : .tournament(TournamentConfig(totalPoints: totalPoints))
        onStart(MatchSettings(format: format, firstServer: server))
    }

    private func resumeSubtitle(_ engine: ScoringEngine) -> String {
        let s = engine.state
        if s.kind == .classic {
            return String(localized: "Сеты \(s.setsWon.you)-\(s.setsWon.opp), геймы \(s.currentGames.you)-\(s.currentGames.opp)")
        } else {
            return "\(s.currentPoints.you) : \(s.currentPoints.opp)"
        }
    }
}
