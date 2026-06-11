# Путь к TestFlight без своего Mac

Гайд: от нуля до первой сборки в TestFlight. Вся настройка делается **с Linux/из браузера** —
macOS работает только на CI-раннере (GitHub Actions), и его ты руками не трогаешь.

> Разделение проекта на два слоя — ключ ко всему:
> - **`ScoringEngine/`** — чистая логика, тестируется на Linux (`swift test`). Mac не нужен.
> - **`App/` + `project.yml`** — watchOS-приложение. Собирается только на macOS, но это делает CI.

---

## Что понадобится (разово)

| Пункт | Стоимость | Зачем |
|---|---|---|
| Apple ID | бесплатно | базовый аккаунт |
| **Apple Developer Program** | **$99/год** | без него TestFlight невозможен |
| GitHub-репозиторий | бесплатно | код + CI (Actions с macOS-раннером) |
| Приватный git-репо для подписи | бесплатно | хранилище сертификатов (fastlane match) |
| iPhone + Apple Watch | — | чтобы реально установить и протестировать сборку |

> $99 нужны только на этом этапе. Логику (`ScoringEngine`) и вёрстку в симуляторе можно
> отрабатывать раньше и бесплатно.

---

## Шаг 1. Apple Developer Program
1. https://developer.apple.com/programs/ → Enroll → оплати $99.
2. Запиши свой **Team ID** (Membership details) — пригодится как секрет `DEVELOPMENT_TEAM`.

## Шаг 2. App Store Connect — карточка приложения
1. https://appstoreconnect.apple.com → My Apps → «+» → New App.
2. Platform: **watchOS**, Bundle ID создашь на след. шаге.
3. Реши свой bundle id, напр. `com.<твоя-компания>.padelwatch`, и пропиши его в:
   - `project.yml` → `PRODUCT_BUNDLE_IDENTIFIER`
   - `fastlane/Appfile` → `app_identifier`

## Шаг 3. App Store Connect API Key (вместо логина/пароля)
1. App Store Connect → Users and Access → **Integrations / Keys** → App Store Connect API → «+».
2. Access: **App Manager**. Скачай файл `AuthKey_XXXX.p8` (даётся один раз!).
3. Запиши: **Key ID** и **Issuer ID**.
4. Преврати ключ в base64 (на Linux):
   ```bash
   base64 -w0 AuthKey_XXXX.p8
   ```
   Вывод пойдёт в секрет `ASC_KEY_CONTENT`.

## Шаг 4. Репозиторий для подписи (fastlane match)
`match` хранит сертификаты и provisioning-профили в приватном git и создаёт их через API key —
**Mac не нужен**.
1. Создай **приватный** git-репо, напр. `padel-watch-certs`.
2. Придумай пароль шифрования → секрет `MATCH_PASSWORD`.
3. URL репо → секрет `MATCH_GIT_URL`.
4. Для доступа CI к этому репо по HTTPS сформируй basic-auth токен:
   ```bash
   echo -n "<github-username>:<personal-access-token>" | base64
   ```
   → секрет `MATCH_GIT_BASIC_AUTHORIZATION`.

## Шаг 5. Секреты в GitHub
Repo → Settings → Secrets and variables → Actions → New repository secret. Заведи все:

| Секрет | Что класть |
|---|---|
| `DEVELOPMENT_TEAM` | Team ID из шага 1 |
| `APP_IDENTIFIER` | твой bundle id |
| `ASC_KEY_ID` | Key ID из шага 3 |
| `ASC_ISSUER_ID` | Issuer ID из шага 3 |
| `ASC_KEY_CONTENT` | base64 от `.p8` (шаг 3) |
| `MATCH_GIT_URL` | URL репо подписи (шаг 4) |
| `MATCH_PASSWORD` | пароль шифрования match (шаг 4) |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 basic-auth (шаг 4) |

## Шаг 6. Инициализировать сертификаты (один раз)
Это можно сделать прямо на CI: запусти workflow вручную (Actions → CI → Run workflow).
При первом прогоне `match(type: "appstore", readonly: false)` создаст distribution-сертификат
и app-store профиль и зальёт их в репо подписи. Дальнейшие сборки используют их повторно.

> Если хочешь подстраховаться — на этом этапе можно один раз арендовать облачный Mac на час
> и выполнить `bundle exec fastlane match appstore` локально. Но обычно CI справляется сам.

## Шаг 7. Иконка приложения
TestFlight требует иконку 1024×1024. Положи PNG в
`App/Assets.xcassets/AppIcon.appiconset/` и пропиши `filename` в его `Contents.json`
(сейчас там пустой слот-заглушка).

## Шаг 8. Запуск
Любой push в `main` запускает CI:
1. **engine-tests** (Linux) — `swift test` по `ScoringEngine`.
2. **testflight** (macOS) — XcodeGen → match → build → upload.

Через несколько минут сборка появится в App Store Connect → TestFlight. Добавь себя как
internal tester, поставь приложение **TestFlight** на iPhone — watch-приложение само
доедет на сопряжённые Apple Watch.

---

## Локальная проверка логики (Linux, бесплатно, без всего вышеперечисленного)
```bash
. "$HOME/.local/share/swiftly/env.sh"
swift test --package-path ScoringEngine
```

## Когда дойдём до вёрстки UI
Для быстрой итерации (симулятор Apple Watch + SwiftUI Previews) понадобится интерактивный
macOS — арендуй облачный Mac по часам (MacinCloud / Scaleway). Проект там открывается так:
```bash
brew install xcodegen
xcodegen generate
open PadelWatch.xcodeproj
```

---

## ⚠️ Важно: конфиг подписи/сборки требует валидации на первом прогоне
`Fastfile`, `project.yml` и workflow написаны по рабочим шаблонам, но **точные детали
сборки именно watchOS-таргета** (имя профиля, export options, иногда deployment target)
почти всегда требуют пары правок на первом реальном запуске на macOS. Это нормально:
первый зелёный прогон CI — отдельная маленькая задача, которую добиваем итеративно по логам.
