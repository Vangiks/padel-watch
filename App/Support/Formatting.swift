import SwiftUI
import ScoringEngine

// Подписи доменных типов как LocalizedStringKey — локализуются через окружение `\.locale`
// (тот же надёжный путь, что и обычные `Text("...")`). Строковый хелпер с явной локалью
// НЕ использовать: `String(localized:locale:)` берёт язык строки из системы, а не из выбранной локали.

extension Team {
    var label: LocalizedStringKey {
        self == .you ? "я" : "противник"
    }
}

extension DeuceMode {
    /// Пресеты для мастера настройки (в порядке отображения).
    static let presets: [DeuceMode] = [.advantage, .goldenPoint, .goldenDouble, .starPoint]

    var title: LocalizedStringKey {
        switch self {
        case .advantage:
            return "Больше/меньше"
        case .suddenDeath(let n):
            switch n {
            case 1: return "Золотой мяч"
            case 2: return "Золотой ×2"
            case 3: return "Star Point"
            default: return "Решающее на deuce \(n)"
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
