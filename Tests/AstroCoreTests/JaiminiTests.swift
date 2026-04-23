import Testing
@testable import AstroCore
import Foundation

@Suite("Jaimini Chara Karakas", .serialized)
struct JaiminiTests {

    private func eph() async -> EphemerisActor {
        await TestEphemeris.initialize()
        return TestEphemeris.shared
    }

    private func swovenChart() async -> BirthChart {
        let birthData = BirthData.from(
            name: "Swoven Pokharel",
            year: 1985, month: 9, day: 10,
            hour: 0, minute: 45, second: 0,
            timeZoneID: "Asia/Kathmandu",
            latitude: 27.7172, longitude: 85.3240
        )
        let calc = ChartCalculator(ephemeris: await eph())
        return await calc.computeChart(for: birthData)
    }

    private func j2000Chart() async -> BirthChart {
        let birthData = BirthData.from(
            name: "J2000", year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneHours: 0.0, latitude: 0.0, longitude: 0.0
        )
        let calc = ChartCalculator(ephemeris: await eph())
        return await calc.computeChart(for: birthData)
    }

    // MARK: - 8-Karaka System

    @Test("8-karaka assigns all 8 karakas")
    func eightKarakaCount() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart, useEightKaraka: true)!

        #expect(result.karakas.count == 8)
        #expect(result.planets.count == 8)
        #expect(result.ranking.count == 8)
        #expect(result.isEightKaraka == true)
    }

    @Test("8-karaka includes Rahu")
    func eightKarakaHasRahu() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart, useEightKaraka: true)!

        #expect(result.karakas[.rahu] != nil, "Rahu should have a karaka in 8-karaka system")
    }

    @Test("8-karaka has Pitrikaraka")
    func eightKarakaHasPitrikaraka() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart, useEightKaraka: true)!

        #expect(result.planets[.pitrikaraka] != nil, "Pitrikaraka should be assigned")
    }

    // MARK: - 7-Karaka System

    @Test("7-karaka assigns 7 karakas, no Rahu")
    func sevenKarakaCount() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart, useEightKaraka: false)!

        #expect(result.karakas.count == 7)
        #expect(result.karakas[.rahu] == nil, "Rahu excluded from 7-karaka")
        #expect(result.planets[.pitrikaraka] == nil, "No Pitrikaraka in 7-karaka")
        #expect(result.isEightKaraka == false)
    }

    // MARK: - Sorting rules

    @Test("Planets sorted descending by degree in sign")
    func descendingDegreeOrder() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart)!

        for i in 1..<result.ranking.count {
            let prev = result.ranking[i - 1].degreeInSign
            let curr = result.ranking[i].degreeInSign
            #expect(prev >= curr, "Ranking should be descending by degree")
        }
    }

    @Test("Atmakaraka has highest degree in sign")
    func atmakarakaHighest() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart)!

        #expect(result.ranking[0].karaka == .atmakaraka)
        let akDegree = result.ranking[0].degreeInSign
        for entry in result.ranking.dropFirst() {
            #expect(akDegree >= entry.degreeInSign,
                    "AK degree should be >= all others")
        }
    }

    @Test("Darakaraka has lowest degree in sign")
    func darakarakaLowest() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart)!

        #expect(result.ranking.last?.karaka == .darakaraka)
    }

    @Test("Rahu degree is inverted (30 - degreeInSign)")
    func rahuDegreeInversion() async throws {
        let chart = await j2000Chart()
        let rahuPos = chart.planets[.rahu]!
        let expectedDeg = 30.0 - rahuPos.degreeInSign

        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart, useEightKaraka: true)!

        let rahuEntry = result.ranking.first { $0.planet == .rahu }!
        #expect(abs(rahuEntry.degreeInSign - expectedDeg) < 0.001)
    }

    // MARK: - Reverse lookup

    @Test("Karaka and planet lookups are consistent")
    func reverseLookup() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart)!

        for (planet, karaka) in result.karakas {
            #expect(result.planets[karaka] == planet)
        }
    }

    // MARK: - Codable

    @Test("CharaKarakaResult is Codable")
    func codableRoundTrip() async throws {
        let chart = await j2000Chart()
        let calc = CharaKarakaCalculator()
        let result = calc.compute(from: chart)!

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(CharaKarakaResult.self, from: data)

        #expect(decoded.karakas.count == result.karakas.count)
        #expect(decoded.isEightKaraka == result.isEightKaraka)
    }

    // MARK: - Swoven's chart

    @Test("Swoven's Chara Karakas — compute and print")
    func swovenKarakas() async throws {
        let chart = await swovenChart()
        let calc = CharaKarakaCalculator()

        let result8 = calc.compute(from: chart, useEightKaraka: true)!
        print("\n=== Swoven's Chara Karakas ===")
        result8.printSummary()

        #expect(result8.karakas.count == 8)
        #expect(result8.planets[.atmakaraka] != nil)
        #expect(result8.planets[.darakaraka] != nil)
    }
}
