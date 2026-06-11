import SwiftUI
import ScoringEngine

/// Пошаговый мастер настройки матча:
/// Формат → (Классика: deuce → сеты | Турнир: очки N) → первая подача → старт.
struct SetupFlowView: View {
    let resumable: ScoringEngine?
    let onResume: () -> Void
    let onStart: (MatchSettings) -> Void

    private enum Step: Hashable { case deuce, sets, points, server, settings }

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
                    Button { isClassic = true; path = [.deuce] } label: {
                        Label("Классика", systemImage: "figure.tennis")
                    }
                    Button { isClassic = false; path = [.points] } label: {
                        Label("Турнир", systemImage: "trophy.fill")
                    }
                }
            }
            .navigationTitle("Падел")
            .toolbar {
                // Шестерёнка → Настройки. Смах влево оставлен свободным под будущую историю матчей.
                ToolbarItem(placement: .topBarTrailing) {
                    Button { path.append(.settings) } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .navigationDestination(for: Step.self) { step in
                switch step {
                case .deuce: deuceStep
                case .sets: setsStep
                case .points: pointsStep
                case .server: serverStep
                case .settings: SettingsView(settings: AppSettings.shared)
                }
            }
        }
    }

    // MARK: Шаги

    private var deuceStep: some View {
        List {
            ForEach(DeuceMode.presets, id: \.title) { mode in
                Button {
                    deuce = mode
                    path.append(.sets)
                } label: {
                    Label(mode.title, systemImage: mode.iconName)
                }
            }
        }
        .navigationTitle("Режим ровно")
    }

    private var setsStep: some View {
        List {
            Button { numberOfSets = 1; path.append(.server) } label: {
                Label("1 сет", systemImage: "1.circle.fill")
            }
            Button { numberOfSets = 3; path.append(.server) } label: {
                Label("3 сета", systemImage: "3.circle.fill")
            }
        }
        .navigationTitle("Сеты")
    }

    private var pointsStep: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    ForEach([16, 24, 32], id: \.self) { preset in
                        Button("\(preset)") { totalPoints = preset }
                            .buttonStyle(.bordered)
                    }
                }
                // Значение показываем внутри степпера; Digital Crown крутит его же.
                Stepper(value: $totalPoints, in: 4...80, step: 1) {
                    Text("\(totalPoints)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .minimumScaleFactor(0.6)
                }
                Button("Далее") { path.append(.server) }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 6)
        }
        .navigationTitle("Очки")
    }

    private var serverStep: some View {
        List {
            Button { finish(server: .you) } label: {
                Label("Подаю я", systemImage: "figure.tennis")
            }
            Button { finish(server: .opponent) } label: {
                Label("Подаёт соперник", systemImage: "person.2.fill")
            }
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
            return appLocalized("Сеты \(s.setsWon.you)-\(s.setsWon.opp), геймы \(s.currentGames.you)-\(s.currentGames.opp)")
        } else {
            return "\(s.currentPoints.you) : \(s.currentPoints.opp)"
        }
    }
}
