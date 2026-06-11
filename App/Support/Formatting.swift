import Foundation
import ScoringEngine

// Отображаемые строки для доменных типов.
// `Text("...")` в SwiftUI локализуется автоматически (литерал = ключ в String Catalog).
// Хелперы ниже возвращают String, поэтому оборачиваем их в `String(localized:)`,
// чтобы они тоже подхватывали перевод из Localizable.xcstrings.

extension Team {
    var shortName: String {
        self == .you ? String(localized: "ты") : String(localized: "соперник")
    }
}

extension DeuceMode {
    /// Пресеты для мастера настройки (в порядке отображения).
    static let presets: [DeuceMode] = [.advantage, .goldenPoint, .goldenDouble, .starPoint]

    var title: String {
        switch self {
        case .advantage:
            return String(localized: "Больше/меньше")
        case .suddenDeath(let n):
            switch n {
            case 1: return String(localized: "Золотой мяч")
            case 2: return String(localized: "Золотой ×2")
            case 3: return String(localized: "Star Point")
            default: return String(localized: "Решающее на deuce \(n)")
            }
        }
    }
}

/// Длительность в формате m:ss.
func formattedDuration(_ t: TimeInterval) -> String {
    let total = Int(t.rounded())
    return String(format: "%d:%02d", total / 60, total % 60)
}
