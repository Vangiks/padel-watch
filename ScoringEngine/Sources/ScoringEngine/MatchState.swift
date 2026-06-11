import Foundation

/// Полностью производное состояние матча, вычисляемое из настроек и журнала очков.
/// Никакого собственного мутируемого состояния — всё считается заново из событий (event-sourcing),
/// что даёт бесплатный undo/redo и корректную «размотку» переходов гейм/сет.
public struct MatchState: Equatable, Sendable {
    public enum Kind: Equatable, Sendable { case classic, tournament }

    public let kind: Kind

    /// Завершённые сеты (счёт по геймам каждого). Для турнира — пусто.
    public let completedSets: [GameScore]
    /// Геймы в текущем (незавершённом) сете. Для турнира — 0-0.
    public let currentGames: GameScore
    /// Идёт ли тай-брейк (счёт 6-6 в текущем сете).
    public let isTiebreak: Bool
    /// Сырые очки текущего розыгрыша: очки гейма / очки тай-брейка / суммарные очки турнира.
    public let currentPoints: GameScore
    /// Выигранные сеты. Для турнира — 0-0.
    public let setsWon: GameScore
    /// Кто подаёт следующее очко.
    public let server: Team
    /// Идёт ли решающее очко (sudden death армирован и сейчас «ровно» — следующий мяч решает гейм).
    public let isDecisivePoint: Bool

    /// Победитель матча, либо `nil`.
    public let matchWinner: Team?
    /// Ничья (только турнир: разыграли N очков поровну).
    public let isDraw: Bool

    /// Отображаемые очки сторон.
    public let youPointDisplay: PointDisplay
    public let oppPointDisplay: PointDisplay

    public var isFinished: Bool { matchWinner != nil || isDraw }

    // MARK: - Вычисление

    static func compute(settings: MatchSettings, points: ArraySlice<Team>) -> MatchState {
        switch settings.format {
        case .classic(let config):
            return computeClassic(config, firstServer: settings.firstServer, points: points)
        case .tournament(let config):
            return computeTournament(config, firstServer: settings.firstServer, points: points)
        }
    }

    // MARK: Классика

    private static func computeClassic(
        _ config: ClassicConfig,
        firstServer: Team,
        points: ArraySlice<Team>
    ) -> MatchState {
        var completedSets: [GameScore] = []
        var setsWon = GameScore()
        var games = GameScore()        // геймы текущего сета
        var gp = GameScore()           // сырые очки текущего гейма
        var deuces = 0                 // сколько раз в текущем гейме был возврат к 40-40
        var tb = GameScore()           // очки тай-брейка
        var inTiebreak = false
        var completedGames = 0         // завершённые геймы за матч (тай-брейк = 1), для базы подачи
        var matchWinner: Team? = nil
        let setsToWin = config.setsToWin
        let threshold = config.deuceMode.suddenDeathThreshold

        for team in points {
            if matchWinner != nil { break }
            let opp = team.other

            if inTiebreak {
                tb[team] += 1
                if tb[team] >= 7 && tb[team] - tb[opp] >= 2 {
                    games[team] += 1            // 7-6
                    completedSets.append(games)
                    setsWon[team] += 1
                    completedGames += 1
                    games = GameScore()
                    tb = GameScore()
                    inTiebreak = false
                    if setsWon[team] >= setsToWin { matchWinner = team }
                }
                continue
            }

            gp[team] += 1
            // Возврат к 40-40: оба >= 3 и поровну.
            if gp.you >= 3 && gp.you == gp.opp { deuces += 1 }

            let armed = threshold.map { deuces >= $0 } ?? false
            let hi = max(gp.you, gp.opp)
            let lo = min(gp.you, gp.opp)
            let leader: Team = gp.you > gp.opp ? .you : .opponent

            let normalWin = hi >= 4 && hi - lo >= 2          // обычный гейм / реализованный advantage
            let suddenWin = armed && hi - lo >= 1            // решающее очко разыграно
            if normalWin || suddenWin {
                games[leader] += 1
                gp = GameScore()
                deuces = 0
                completedGames += 1

                if games.you == 6 && games.opp == 6 {
                    inTiebreak = true
                } else {
                    let ghi = max(games.you, games.opp)
                    let glo = min(games.you, games.opp)
                    if ghi >= 6 && ghi - glo >= 2 {
                        let setWinner: Team = games.you > games.opp ? .you : .opponent
                        completedSets.append(games)
                        setsWon[setWinner] += 1
                        games = GameScore()
                        if setsWon[setWinner] >= setsToWin { matchWinner = setWinner }
                    }
                }
            }
        }

        // Подача.
        let base: Team = (completedGames % 2 == 0) ? firstServer : firstServer.other
        let server: Team
        if inTiebreak {
            server = tiebreakServer(base: base, pointIndex: tb.you + tb.opp)
        } else {
            server = base
        }

        // Отображение очков и «решающего».
        let displays: (PointDisplay, PointDisplay)
        let currentPoints: GameScore
        var isDecisive = false
        if inTiebreak {
            displays = (.number(tb.you), .number(tb.opp))
            currentPoints = tb
        } else {
            displays = classicGameLabels(gp)
            currentPoints = gp
            let armed = threshold.map { deuces >= $0 } ?? false
            isDecisive = armed && gp.you == gp.opp && gp.you >= 3
        }

        return MatchState(
            kind: .classic,
            completedSets: completedSets,
            currentGames: games,
            isTiebreak: inTiebreak,
            currentPoints: currentPoints,
            setsWon: setsWon,
            server: server,
            isDecisivePoint: matchWinner == nil ? isDecisive : false,
            matchWinner: matchWinner,
            isDraw: false,
            youPointDisplay: displays.0,
            oppPointDisplay: displays.1
        )
    }

    /// Подающий в тай-брейке: первое очко — `base`, далее чередование каждые 2 очка.
    private static func tiebreakServer(base: Team, pointIndex: Int) -> Team {
        if pointIndex == 0 { return base }
        let group = (pointIndex - 1) / 2   // 0,0,1,1,2,2,...
        return (group % 2 == 0) ? base.other : base
    }

    /// Подписи очков обычного гейма. AD — только у ведущего, у второго остаётся 40.
    private static func classicGameLabels(_ g: GameScore) -> (PointDisplay, PointDisplay) {
        func base(_ n: Int) -> PointDisplay {
            switch min(n, 3) {
            case 0: return .love
            case 1: return .fifteen
            case 2: return .thirty
            default: return .forty
            }
        }
        if g.you >= 3 && g.opp >= 3 {
            if g.you == g.opp { return (.forty, .forty) }
            else if g.you > g.opp { return (.advantage, .forty) }
            else { return (.forty, .advantage) }
        }
        return (base(g.you), base(g.opp))
    }

    // MARK: Турнир (Americano/Mexicano)

    private static func computeTournament(
        _ config: TournamentConfig,
        firstServer: Team,
        points: ArraySlice<Team>
    ) -> MatchState {
        var pts = GameScore()
        let n = config.totalPoints
        for team in points {
            if pts.you + pts.opp >= n { break }
            pts[team] += 1
        }

        let finished = pts.you + pts.opp >= n
        var winner: Team? = nil
        var draw = false
        if finished {
            if pts.you > pts.opp { winner = .you }
            else if pts.opp > pts.you { winner = .opponent }
            else { draw = true }
        }

        // Подача переходит каждые 2 очка.
        let played = pts.you + pts.opp
        let server: Team = ((played / 2) % 2 == 0) ? firstServer : firstServer.other

        return MatchState(
            kind: .tournament,
            completedSets: [],
            currentGames: GameScore(),
            isTiebreak: false,
            currentPoints: pts,
            setsWon: GameScore(),
            server: server,
            isDecisivePoint: false,
            matchWinner: winner,
            isDraw: draw,
            youPointDisplay: .number(pts.you),
            oppPointDisplay: .number(pts.opp)
        )
    }
}
