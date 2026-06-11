import Foundation
import ScoringEngine

// Отображаемые строки для доменных типов. Литералы пока на русском; Text(...) в SwiftUI
// использует LocalizedStringKey, так что позже строки выносятся в String Catalog без правок вью.

extension Team {
    var shortName: String { self == .you ? "ты" : "соперник" }
}

extension DeuceMode {
    /// Пресеты для мастера настройки (в порядке отображения).
    static let presets: [DeuceMode] = [.advantage, .goldenPoint, .goldenDouble, .starPoint]

    var title: String {
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
}
