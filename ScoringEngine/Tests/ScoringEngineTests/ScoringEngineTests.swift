import XCTest
@testable import ScoringEngine

final class ScoringEngineTests: XCTestCase {

    // MARK: - Хелперы

    private func classic(sets: Int = 1, deuce: DeuceMode = .advantage, firstServer: Team = .you) -> ScoringEngine {
        ScoringEngine(settings: MatchSettings(
            format: .classic(ClassicConfig(numberOfSets: sets, deuceMode: deuce)),
            firstServer: firstServer
        ))
    }

    private func tournament(_ n: Int, firstServer: Team = .you) -> ScoringEngine {
        ScoringEngine(settings: MatchSettings(
            format: .tournament(TournamentConfig(totalPoints: n)),
            firstServer: firstServer
        ))
    }

    private func play(_ engine: inout ScoringEngine, _ seq: [Team]) {
        for t in seq { engine.pointWon(by: t) }
    }

    /// Выиграть `count` геймов «всухую» командой `team` (по 4 очка на гейм).
    private func winGames(_ engine: inout ScoringEngine, _ team: Team, _ count: Int) {
        for _ in 0..<count { play(&engine, Array(repeating: team, count: 4)) }
    }

    // MARK: - Прогрессия очков в гейме

    func testPointLabels() {
        var e = classic()
        XCTAssertEqual(e.state.youPointDisplay.text, "0")
        e.pointWon(by: .you); XCTAssertEqual(e.state.youPointDisplay.text, "15")
        e.pointWon(by: .you); XCTAssertEqual(e.state.youPointDisplay.text, "30")
        e.pointWon(by: .you); XCTAssertEqual(e.state.youPointDisplay.text, "40")
        e.pointWon(by: .you) // гейм
        XCTAssertEqual(e.state.currentGames.you, 1)
        XCTAssertEqual(e.state.youPointDisplay.text, "0") // новый гейм
    }

    // MARK: - Deuce: больше/меньше (advantage без предела)

    func testAdvantageUnlimited() {
        var e = classic(deuce: .advantage)
        play(&e, [.you, .you, .you, .opponent, .opponent, .opponent]) // 40-40
        XCTAssertEqual(e.state.youPointDisplay.text, "40")
        XCTAssertEqual(e.state.oppPointDisplay.text, "40")
        XCTAssertFalse(e.state.isDecisivePoint)

        e.pointWon(by: .you) // AD ты
        XCTAssertEqual(e.state.youPointDisplay.text, "AD")
        XCTAssertEqual(e.state.oppPointDisplay.text, "40")

        e.pointWon(by: .opponent) // снова 40-40
        XCTAssertEqual(e.state.youPointDisplay.text, "40")
        XCTAssertEqual(e.state.oppPointDisplay.text, "40")
        XCTAssertEqual(e.state.currentGames.you, 0)

        e.pointWon(by: .opponent) // AD соперник
        e.pointWon(by: .opponent) // гейм соперника
        XCTAssertEqual(e.state.currentGames.opp, 1)
    }

    // MARK: - Deuce: Золотой мяч (N=1)

    func testGoldenPoint() {
        var e = classic(deuce: .goldenPoint)
        play(&e, [.you, .you, .you, .opponent, .opponent, .opponent]) // 40-40 = deuce #1
        XCTAssertTrue(e.state.isDecisivePoint, "на первом 40-40 уже решающее")
        e.pointWon(by: .you) // решающее -> гейм
        XCTAssertEqual(e.state.currentGames.you, 1)
    }

    // MARK: - Deuce: Золотой ×2 (N=2)

    func testGoldenDouble() {
        var e = classic(deuce: .goldenDouble)
        play(&e, [.you, .you, .you, .opponent, .opponent, .opponent]) // 40-40 deuce #1
        XCTAssertFalse(e.state.isDecisivePoint)
        e.pointWon(by: .you)        // AD
        XCTAssertEqual(e.state.youPointDisplay.text, "AD")
        XCTAssertFalse(e.state.isDecisivePoint)
        e.pointWon(by: .opponent)   // 40-40 deuce #2 -> решающее
        XCTAssertTrue(e.state.isDecisivePoint)
        e.pointWon(by: .opponent)   // решающее -> гейм сопернику
        XCTAssertEqual(e.state.currentGames.opp, 1)
    }

    // MARK: - Deuce: Star Point (N=3)

    func testStarPoint() {
        var e = classic(deuce: .starPoint)
        play(&e, [.you, .you, .you, .opponent, .opponent, .opponent]) // deuce #1
        play(&e, [.you, .opponent]) // AD ты -> deuce #2
        XCTAssertFalse(e.state.isDecisivePoint)
        play(&e, [.you, .opponent]) // AD ты -> deuce #3
        XCTAssertTrue(e.state.isDecisivePoint, "на 3-м 40-40 решающее")
        e.pointWon(by: .you) // гейм
        XCTAssertEqual(e.state.currentGames.you, 1)
    }

    // MARK: - Завершение сета

    func testSetWin6_4() {
        var e = classic(sets: 1)
        for i in 0..<8 { winGames(&e, i % 2 == 0 ? .you : .opponent, 1) } // 4-4
        winGames(&e, .you, 2) // 5-4, затем 6-4
        XCTAssertEqual(e.state.matchWinner, .you)
        XCTAssertEqual(e.state.completedSets.first, GameScore(you: 6, opp: 4))
    }

    func testSetEndsEarlyAt6_0() {
        var e = classic(sets: 1)
        winGames(&e, .you, 6) // 6-0, матч best-of-1 окончен
        XCTAssertEqual(e.state.matchWinner, .you)
        XCTAssertEqual(e.state.completedSets.first, GameScore(you: 6, opp: 0))
    }

    func testSet7_5() {
        var e = classic(sets: 1)
        // 5-5, затем 6-5, затем 7-5
        for i in 0..<10 { winGames(&e, i % 2 == 0 ? .you : .opponent, 1) } // 5-5
        XCTAssertEqual(e.state.currentGames, GameScore(you: 5, opp: 5))
        winGames(&e, .you, 1) // 6-5
        XCTAssertEqual(e.state.currentGames, GameScore(you: 6, opp: 5))
        XCTAssertNil(e.state.matchWinner)
        winGames(&e, .you, 1) // 7-5
        XCTAssertEqual(e.state.matchWinner, .you)
        XCTAssertEqual(e.state.completedSets.first, GameScore(you: 7, opp: 5))
    }

    // MARK: - Тай-брейк

    func testTiebreakAt6_6() {
        var e = classic(sets: 1)
        for i in 0..<12 { winGames(&e, i % 2 == 0 ? .you : .opponent, 1) } // 6-6
        XCTAssertTrue(e.state.isTiebreak)
        XCTAssertEqual(e.state.currentGames, GameScore(you: 6, opp: 6))

        // 7-0 тай-брейк
        play(&e, Array(repeating: .you, count: 7))
        XCTAssertEqual(e.state.matchWinner, .you)
        XCTAssertEqual(e.state.completedSets.first, GameScore(you: 7, opp: 6))
    }

    func testTiebreakWinByTwo() {
        var e = classic(sets: 1)
        for i in 0..<12 { winGames(&e, i % 2 == 0 ? .you : .opponent, 1) } // 6-6
        // до 6-6 в тай-брейке
        for _ in 0..<6 { play(&e, [.you, .opponent]) }
        XCTAssertTrue(e.state.isTiebreak)
        XCTAssertNil(e.state.matchWinner) // 6-6, нужна разница 2
        play(&e, [.you]) // 7-6
        XCTAssertNil(e.state.matchWinner)
        play(&e, [.you]) // 8-6
        XCTAssertEqual(e.state.matchWinner, .you)
    }

    // MARK: - Матч best-of-3

    func testBestOfThree() {
        var e = classic(sets: 3)
        winGames(&e, .you, 6)      // сет 1: 6-0
        XCTAssertEqual(e.state.setsWon, GameScore(you: 1, opp: 0))
        XCTAssertNil(e.state.matchWinner)
        winGames(&e, .opponent, 6) // сет 2: соперник 6-0
        XCTAssertEqual(e.state.setsWon, GameScore(you: 1, opp: 1))
        winGames(&e, .you, 6)      // сет 3
        XCTAssertEqual(e.state.matchWinner, .you)
        XCTAssertEqual(e.state.completedSets.count, 3)
    }

    // MARK: - Подача: классика чередуется по геймам

    func testServerAlternatesByGame() {
        var e = classic(firstServer: .you)
        XCTAssertEqual(e.state.server, .you)
        winGames(&e, .you, 1)
        XCTAssertEqual(e.state.server, .opponent)
        winGames(&e, .opponent, 1)
        XCTAssertEqual(e.state.server, .you)
    }

    // MARK: - Подача в тай-брейке: 1 очко, далее каждые 2

    func testTiebreakServerPattern() {
        var e = classic(firstServer: .you)
        for i in 0..<12 { winGames(&e, i % 2 == 0 ? .you : .opponent, 1) } // 6-6
        // 12 геймов сыграно -> база подачи = firstServer (you)
        XCTAssertTrue(e.state.isTiebreak)
        XCTAssertEqual(e.state.server, .you)         // очко 0
        e.pointWon(by: .you)
        XCTAssertEqual(e.state.server, .opponent)    // очко 1
        e.pointWon(by: .you)
        XCTAssertEqual(e.state.server, .opponent)    // очко 2
        e.pointWon(by: .you)
        XCTAssertEqual(e.state.server, .you)         // очко 3
    }

    // MARK: - Подача продолжает чередование в новом сете (тай-брейк = 1 гейм)

    func testServerContinuesAfterTiebreak() {
        var e = classic(sets: 3, firstServer: .you)
        for i in 0..<12 { winGames(&e, i % 2 == 0 ? .you : .opponent, 1) } // 6-6
        play(&e, Array(repeating: .you, count: 7)) // тай-брейк 7-0, сет закрыт (13-й «гейм»)
        XCTAssertEqual(e.state.setsWon, GameScore(you: 1, opp: 0))
        // Сыграно 13 геймов (нечётно) -> первый гейм нового сета подаёт соперник.
        XCTAssertEqual(e.state.server, .opponent)
    }

    // MARK: - Турнир

    func testTournamentWinner() {
        var e = tournament(24)
        play(&e, Array(repeating: .you, count: 16))
        play(&e, Array(repeating: .opponent, count: 8)) // 16-8, сумма 24
        XCTAssertEqual(e.state.currentPoints, GameScore(you: 16, opp: 8))
        XCTAssertEqual(e.state.matchWinner, .you)
        XCTAssertFalse(e.state.isDraw)
        XCTAssertTrue(e.state.isFinished)
    }

    func testTournamentDraw() {
        var e = tournament(24)
        for _ in 0..<12 { play(&e, [.you, .opponent]) } // 12-12
        XCTAssertTrue(e.state.isDraw)
        XCTAssertNil(e.state.matchWinner)
        XCTAssertTrue(e.state.isFinished)
    }

    func testTournamentStopsAtN() {
        var e = tournament(10)
        play(&e, Array(repeating: .you, count: 20)) // пытаемся переполнить
        XCTAssertEqual(e.state.currentPoints.you, 10) // не больше N
    }

    func testTournamentServerEveryTwoPoints() {
        var e = tournament(24, firstServer: .you)
        XCTAssertEqual(e.state.server, .you)      // очки 0,1
        e.pointWon(by: .you)
        XCTAssertEqual(e.state.server, .you)
        e.pointWon(by: .you)                      // сыграно 2
        XCTAssertEqual(e.state.server, .opponent) // очки 2,3
        e.pointWon(by: .you)
        XCTAssertEqual(e.state.server, .opponent)
        e.pointWon(by: .you)                      // сыграно 4
        XCTAssertEqual(e.state.server, .you)
    }

    // MARK: - Undo / Redo

    func testUndoRedo() {
        var e = classic()
        play(&e, [.you, .you]) // 30-0
        XCTAssertEqual(e.state.youPointDisplay.text, "30")
        e.undo()
        XCTAssertEqual(e.state.youPointDisplay.text, "15")
        e.redo()
        XCTAssertEqual(e.state.youPointDisplay.text, "30")
    }

    func testNewPointDiscardsRedoBranch() {
        var e = classic()
        play(&e, [.you, .you]) // 30-0
        e.undo()               // 15-0
        XCTAssertTrue(e.canRedo)
        e.pointWon(by: .opponent) // новое очко -> ветка redo отброшена
        XCTAssertFalse(e.canRedo)
        XCTAssertEqual(e.state.youPointDisplay.text, "15")
        XCTAssertEqual(e.state.oppPointDisplay.text, "15")
    }

    func testUndoUnwindsGameTransition() {
        var e = classic()
        winGames(&e, .you, 1) // 1 гейм
        XCTAssertEqual(e.state.currentGames.you, 1)
        e.undo() // откат последнего (победного) очка
        XCTAssertEqual(e.state.currentGames.you, 0)
        XCTAssertEqual(e.state.youPointDisplay.text, "40")
    }

    // MARK: - Завершённый матч игнорирует очки

    func testIgnorePointsAfterMatchOver() {
        var e = classic(sets: 1)
        winGames(&e, .you, 6) // матч окончен
        XCTAssertEqual(e.state.matchWinner, .you)
        let before = e.appliedPoints.count
        e.pointWon(by: .opponent)
        XCTAssertEqual(e.appliedPoints.count, before) // ничего не добавилось
    }

    // MARK: - Сериализация (персистентность)

    func testCodableRoundTrip() throws {
        var e = classic(sets: 3, deuce: .starPoint, firstServer: .opponent)
        play(&e, [.you, .you, .opponent, .you])
        e.undo()
        let data = try JSONEncoder().encode(e)
        let restored = try JSONDecoder().decode(ScoringEngine.self, from: data)
        XCTAssertEqual(e, restored)
        XCTAssertEqual(e.state, restored.state)
    }
}
