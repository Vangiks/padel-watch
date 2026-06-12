import Foundation

/// Персистентность текущего (активного) матча: `MatchRecord` пишется на диск после каждого очка,
/// чтобы пережить вылет/перезапуск и предложить «Продолжить матч?».
/// Это та же запись, что уходит в `HistoryStore` при завершении — отсюда `id`/`startedAt` живут
/// с момента старта матча.
struct MatchStore {
    static let shared = MatchStore()

    private let url: URL

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = dir.appendingPathComponent("current-match.json")
    }

    func save(_ record: MatchRecord) {
        do {
            let data = try JSONEncoder().encode(record)
            try data.write(to: url, options: .atomic)
        } catch {
            // Персистентность — не критичный путь; не роняем игру из-за ошибки записи.
            print("MatchStore save error: \(error)")
        }
    }

    func load() -> MatchRecord? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MatchRecord.self, from: data)
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
