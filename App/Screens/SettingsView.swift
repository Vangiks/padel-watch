import SwiftUI

/// Экран настроек: язык интерфейса (и место для будущих опций).
struct SettingsView: View {
    @Bindable var settings: AppSettings

    var body: some View {
        List {
            Picker(selection: $settings.language) {
                ForEach(AppSettings.Language.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            } label: {
                Label("Язык", systemImage: "globe")
            }

            Toggle(isOn: $settings.trackActivity) {
                Label("Отслеживать активность", systemImage: "heart.fill")
            }
        }
        .navigationTitle("Настройки")
    }
}
