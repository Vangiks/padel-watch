# Padel Watch

Приложение для счёта в паделе на Apple Watch (нативный SwiftUI, standalone watchOS).

## Структура

| Путь | Что это |
|---|---|
| `ScoringEngine/` | Чистая логика счёта (SwiftPM-пакет). Тестируется на Linux. |
| `App/` | watchOS-приложение (SwiftUI). Пока скелет — вертикальный срез на движке. |
| `project.yml` | Описание Xcode-проекта как код (XcodeGen). |
| `fastlane/` | Сборка и заливка в TestFlight. |
| `.github/workflows/ci.yml` | CI: тесты логики на Linux + сборка/деплой на macOS. |
| `docs/TESTFLIGHT.md` | Пошаговый гайд «от Apple ID до первой сборки в TestFlight». |

## Тесты логики (без Mac)

```bash
. "$HOME/.local/share/swiftly/env.sh"   # Swift 6.x, установлен через swiftly
swift test --package-path ScoringEngine
```

## Сборка приложения

watchOS собирается только на macOS — это делает CI (см. [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md)).
Для вёрстки UI с симулятором — облачный Mac:

```bash
brew install xcodegen && xcodegen generate && open PadelWatch.xcodeproj
```

## Форматы счёта

- **Классика**: очко→гейм→сет→матч (1 или 3 сета). Сет до 6 (разница 2), тай-брейк 7-6 при 6-6.
  Режимы deuce: больше/меньше · Золотой мяч · Золотой ×2 · Star Point.
- **Турнир** (Americano/Mexicano): копим сумму N очков, побеждает у кого больше, ничья допустима.
