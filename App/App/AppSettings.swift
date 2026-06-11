import Foundation
import Observation

/// Глобальные настройки приложения (язык и т.д.), сохраняются в UserDefaults.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    enum Language: String, CaseIterable, Identifiable {
        case system, ru, en
        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .system: return appLocalized("Системный")
            case .ru: return "Русский"
            case .en: return "English"
            }
        }
    }

    var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.key) }
    }

    private static let key = "app.language"

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.key) ?? Language.system.rawValue
        language = Language(rawValue: raw) ?? .system
    }

    /// Явная локаль для строк-хелперов; `nil` для системной.
    private var locale: Locale? {
        switch language {
        case .system: return nil
        case .ru: return Locale(identifier: "ru")
        case .en: return Locale(identifier: "en")
        }
    }

    /// Локаль для применения в окружении и в `String(localized:locale:)`.
    var resolvedLocale: Locale { locale ?? .autoupdatingCurrent }
}

/// Локализованная строка с учётом выбранного в приложении языка.
/// Для `Text("...")` достаточно окружения `\.locale`; это — для мест, где строится `String`.
func appLocalized(_ value: String.LocalizationValue) -> String {
    String(localized: value, locale: AppSettings.shared.resolvedLocale)
}
