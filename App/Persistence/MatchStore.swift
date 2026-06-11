import Foundation
import ScoringEngine

/// Персистентность текущего матча: журнал событий пишется на диск после каждого очка,
/// чтобы пережить вылет/перезапуск и предложить «Продолжить матч?».
struct MatchStore {
    static let shared = MatchStore()

    private let url: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = dir.appendingPathComponent("current-match.json")
    }

    func save(_ engine: ScoringEngine) {
        do {
            let data = try JSONEncoder().encode(engine)
            try data.write(to: url, options: .atomic)
        } catch {
            // Персистентность — не критичный путь; не роняем игру из-за ошибки записи.
            print("MatchStore save error: \(error)")
        }
    }

    func load() -> ScoringEngine? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ScoringEngine.self, from: data)
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
