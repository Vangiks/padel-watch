import Foundation

/// Сводка завершённой тренировки для экрана итога и записи в Историю.
/// `Codable` — чтобы сохраняться внутри `MatchRecord`.
/// Замечание: `heartRateBPM` — последний замер пульса, не средний за матч (известное упрощение).
struct WorkoutSummary: Equatable, Codable {
    var duration: TimeInterval
    var activeEnergyKcal: Double
    var heartRateBPM: Double
}

#if os(watchOS)
import HealthKit
import Observation

/// Управление workout-сессией HealthKit: старт при начале матча, пульс/калории в реальном времени,
/// пауза/возобновление, корректное завершение и сохранение в «Здоровье».
///
/// Всё устойчиво к отсутствию доступа: если HealthKit недоступен или авторизация не дана,
/// методы тихо ничего не делают — приложение продолжает работать (важно для симулятора).
@MainActor
@Observable
final class WorkoutManager: NSObject {
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var startDate: Date?

    private(set) var heartRate: Double = 0
    private(set) var activeEnergy: Double = 0
    private(set) var isRunning = false

    // Делегаты HealthKit требуют NSObject — отсюда наследование и super.init().
    override init() { super.init() }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        let share: Set = [HKQuantityType.workoutType()]
        let read: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.activeEnergyBurned)
        ]
        try? await healthStore.requestAuthorization(toShare: share, read: read)
    }

    func start() {
        guard isAvailable, session == nil else { return }
        let config = HKWorkoutConfiguration()
        // Нативного типа «падел» в HealthKit нет — ближайший аналог теннис.
        config.activityType = .tennis
        config.locationType = .indoor
        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self

            let start = Date()
            self.session = session
            self.builder = builder
            self.startDate = start
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { _, _ in }
            isRunning = true
        } catch {
            print("WorkoutManager start error: \(error)")
        }
    }

    func pause() { session?.pause() }
    func resume() { session?.resume() }

    /// Завершить сессию и вернуть сводку (сохраняется в «Здоровье»).
    func end() async -> WorkoutSummary? {
        guard let session, let builder else { return nil }
        session.end()
        let fallbackDuration = startDate.map { Date().timeIntervalSince($0) } ?? 0
        defer { cleanup() }
        do {
            try await builder.endCollection(at: Date())
            let workout = try await builder.finishWorkout()
            return WorkoutSummary(
                duration: workout?.duration ?? fallbackDuration,
                activeEnergyKcal: activeEnergy,
                heartRateBPM: heartRate
            )
        } catch {
            print("WorkoutManager end error: \(error)")
            return WorkoutSummary(duration: fallbackDuration, activeEnergyKcal: activeEnergy, heartRateBPM: heartRate)
        }
    }

    private func cleanup() {
        session = nil
        builder = nil
        startDate = nil
        isRunning = false
    }
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ builder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        // Извлекаем значения в nonisolated-контексте и переносим на главный актор только Double.
        var hr: Double?
        var energy: Double?
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let stats = builder.statistics(for: quantityType) else { continue }
            if quantityType == HKQuantityType(.heartRate) {
                hr = stats.mostRecentQuantity()?.doubleValue(for: HKUnit(from: "count/min"))
            } else if quantityType == HKQuantityType(.activeEnergyBurned) {
                energy = stats.sumQuantity()?.doubleValue(for: .kilocalorie())
            }
        }
        let hrValue = hr
        let energyValue = energy
        Task { @MainActor in
            if let hrValue { self.heartRate = hrValue }
            if let energyValue { self.activeEnergy = energyValue }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ builder: HKLiveWorkoutBuilder) {}
}

extension WorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(_ session: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {}

    nonisolated func workoutSession(_ session: HKWorkoutSession, didFailWithError error: Error) {
        print("WorkoutManager session error: \(error)")
    }
}
#endif
