// swift-tools-version: 5.9
import PackageDescription

// Чистый, платформо-независимый модуль доменной логики счёта.
// Никаких зависимостей от watchOS/HealthKit — это позволяет гонять тесты на любой машине
// (`swift test`) и переиспользовать ядро в будущем (в т.ч. портировать в веб).
let package = Package(
    name: "ScoringEngine",
    products: [
        .library(name: "ScoringEngine", targets: ["ScoringEngine"])
    ],
    targets: [
        .target(name: "ScoringEngine"),
        .testTarget(name: "ScoringEngineTests", dependencies: ["ScoringEngine"])
    ]
)
