import Foundation

/// Команда. В MVP всего две стороны: «ты» и «соперник».
public enum Team: String, Codable, Sendable, CaseIterable {
    case you
    case opponent

    public var other: Team { self == .you ? .opponent : .you }
}

/// Пара чисел «ты — соперник». Используется для очков, геймов, сетов.
public struct GameScore: Equatable, Sendable, Codable {
    public var you: Int
    public var opp: Int

    public init(you: Int = 0, opp: Int = 0) {
        self.you = you
        self.opp = opp
    }

    public subscript(_ team: Team) -> Int {
        get { team == .you ? you : opp }
        set { if team == .you { you = newValue } else { opp = newValue } }
    }
}

/// Режим розыгрыша «ровно» (deuce) в классике.
/// Унифицирован одним параметром: на каком по счёту 40-40 включается решающее очко.
public enum DeuceMode: Codable, Sendable, Equatable {
    /// Больше/меньше — классический advantage без предела.
    case advantage
    /// Решающее очко включается на `atDeuce`-м возврате к 40-40 (N >= 1).
    case suddenDeath(atDeuce: Int)

    /// «Золотой мяч» (punto de oro): решающее сразу на первом 40-40.
    public static let goldenPoint = DeuceMode.suddenDeath(atDeuce: 1)
    /// «Золотой ×2»: 40-40 → больше/меньше → снова 40-40 → решающее.
    public static let goldenDouble = DeuceMode.suddenDeath(atDeuce: 2)
    /// «Star Point»: три раза 40-40, на 3-м решающее.
    public static let starPoint = DeuceMode.suddenDeath(atDeuce: 3)

    /// Номер deuce, начиная с которого розыгрыш становится решающим. `nil` — никогда (advantage).
    var suddenDeathThreshold: Int? {
        switch self {
        case .advantage: return nil
        case .suddenDeath(let n): return n
        }
    }
}

/// Настройки классического формата (очко → гейм → сет → матч).
public struct ClassicConfig: Codable, Sendable, Equatable {
    /// Число сетов в матче: 1 или 3.
    public var numberOfSets: Int
    public var deuceMode: DeuceMode

    public init(numberOfSets: Int, deuceMode: DeuceMode) {
        self.numberOfSets = numberOfSets
        self.deuceMode = deuceMode
    }

    /// Сколько сетов нужно выиграть для победы в матче: 1 → 1, 3 → 2.
    public var setsToWin: Int { numberOfSets / 2 + 1 }
}

/// Настройки турнирного формата (Americano/Mexicano): плоская модель «копим очки до суммы N».
public struct TournamentConfig: Codable, Sendable, Equatable {
    /// Суммарное число разыгрываемых очков. Матч стоп при `you + opp == totalPoints`.
    public var totalPoints: Int

    public init(totalPoints: Int) {
        self.totalPoints = totalPoints
    }
}

/// Формат матча.
public enum MatchFormat: Codable, Sendable, Equatable {
    case classic(ClassicConfig)
    case tournament(TournamentConfig)
}

/// Полные настройки матча: формат + кто подаёт первым.
public struct MatchSettings: Codable, Sendable, Equatable {
    public var format: MatchFormat
    public var firstServer: Team

    public init(format: MatchFormat, firstServer: Team) {
        self.format = format
        self.firstServer = firstServer
    }
}

/// Отображаемое значение очка. UI маппит это в локализованную строку.
public enum PointDisplay: Equatable, Sendable {
    case love          // 0
    case fifteen       // 15
    case thirty        // 30
    case forty         // 40
    case advantage     // AD
    case number(Int)   // тай-брейк и турнир: 0,1,2,...

    /// Нейтральное текстовое представление (для отладки/тестов; не локализовано).
    public var text: String {
        switch self {
        case .love: return "0"
        case .fifteen: return "15"
        case .thirty: return "30"
        case .forty: return "40"
        case .advantage: return "AD"
        case .number(let n): return String(n)
        }
    }
}
