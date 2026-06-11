import Foundation
import ScoringEngine

// Отображаемые строки для доменных типов.
// `Text("...")` в SwiftUI локализуется автоматически (литерал = ключ в String Catalog).
// Хелперы ниже возвращают String, поэтому оборачиваем их в `String(localized:)`,
// чтобы они тоже подхватывали перевод из Localizable.xcstrings.

extension Team {
    var shortName: String {
        self == .you ? appLocalized("ты") : appLocalized("соперник")
    }
}

extension DeuceMode {
    /// Пресеты для мастера настройки (в порядке отображения).
    static let presets: [DeuceMode] = [.advantage, .goldenPoint, .goldenDouble, .starPoint]

    var title: String {
        switch self {
        case .advantage:
            return appLocalized("Больше/меньше")
        case .suddenDeath(let n):
            switch n {
            case 1: return appLocalized("Золотой мяч")
            case 2: return appLocalized("Золотой ×2")
            case 3: return appLocalized("Star Point")
            default: return appLocalized("Решающее на deuce \(n)")
            }
        }
    }

    /// SF Symbol для пункта в мастере настройки.
    var iconName: String {
        switch self {
        case .advantage:
            return "infinity"
        case .suddenDeath(let n):
            switch n {
            case 1: return "star.fill"
            case 2: return "star.leadinghalf.filled"
            case 3: return "sparkles"
            default: return "circle.fill"
            }
        }
    }
}

/// Длительность в формате m:ss.
func formattedDuration(_ t: TimeInterval) -> String {
    let total = Int(t.rounded())
    return String(format: "%d:%02d", total / 60, total % 60)
}
