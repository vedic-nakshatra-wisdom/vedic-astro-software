import Testing
@testable import AstroCore
import Foundation

@Suite("Vimshottari Dasha", .serialized)
struct VimshottariTests {

    private func eph() async -> EphemerisActor {
        await TestEphemeris.initialize()
        return TestEphemeris.shared
    }

    private func computeJ2000Chart() async -> BirthChart {
        let birthData = BirthData.from(
            name: "J2000", year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneHours: 0.0, latitude: 0.0, longitude: 0.0
        )
        let calc = ChartCalculator(ephemeris: await eph())
        return await calc.computeChart(for: birthData)
    }

    @Test("Vimshottari years total 120")
    func totalYears() {
        let total = Planet.allCases.reduce(0.0) { $0 + $1.vimshottariYears }
        #expect(total == 120.0)
    }

    @Test("Cycle order contains all 9 planets")
    func cycleOrder() {
        #expect(VimshottariCalculator.cycleOrder.count == 9)
        #expect(Set(VimshottariCalculator.cycleOrder) == Set(Planet.allCases))
    }

    @Test("Fraction elapsed at nakshatra boundaries")
    func fractionBoundaries() {
        // Start of Ashwini (0°)
        #expect(Nakshatra.fractionElapsed(at: 0.0) == 0.0)
        // Middle of Ashwini (~6.667°)
        let mid = Nakshatra.fractionElapsed(at: Nakshatra.span / 2.0)
        #expect(abs(mid - 0.5) < 0.001)
        // Just before end of Ashwini
        let nearEnd = Nakshatra.fractionElapsed(at: Nakshatra.span - 0.001)
        #expect(nearEnd > 0.99)
    }

    @Test("9 Maha Dasha periods generated")
    func nineMahaDashas() async throws {
        let chart = await computeJ2000Chart()
        let calc = VimshottariCalculator()
        let dashas = calc.computeDashas(from: chart, levels: 1)!
        #expect(dashas.count == 9)
        // All periods should be contiguous
        for i in 1..<dashas.count {
            #expect(dashas[i].startDate == dashas[i - 1].endDate)
        }
    }

    @Test("Each Maha Dasha has 9 Antar sub-periods")
    func antarDashas() async throws {
        let chart = await computeJ2000Chart()
        let calc = VimshottariCalculator()
        let dashas = calc.computeDashas(from: chart, levels: 2)!
        for maha in dashas {
            #expect(maha.subPeriods.count == 9)
            // Antar periods should be contiguous within Maha
            for i in 1..<maha.subPeriods.count {
                #expect(maha.subPeriods[i].startDate == maha.subPeriods[i - 1].endDate)
            }
        }
    }

    @Test("Antar durations sum to Maha duration")
    func antarDurationSum() async throws {
        let chart = await computeJ2000Chart()
        let calc = VimshottariCalculator()
        let dashas = calc.computeDashas(from: chart, levels: 2)!
        for maha in dashas {
            let mahaDays = maha.durationDays
            let antarSum = maha.subPeriods.reduce(0.0) { $0 + $1.durationDays }
            #expect(abs(mahaDays - antarSum) < 0.01, "Antar sum should equal Maha duration for \(maha.planet.rawValue)")
        }
    }

    @Test("Returns nil for no-birth-time chart")
    func noBirthTime() async throws {
        let birthData = BirthData(
            name: "Unknown",
            dateTimeUTC: Date(timeIntervalSince1970: 946728000),
            timeZoneOffset: 0, latitude: 0, longitude: 0,
            hasBirthTime: false
        )
        let calcChart = ChartCalculator(ephemeris: await eph())
        let chart = await calcChart.computeChart(for: birthData)
        let dashaCalc = VimshottariCalculator()
        #expect(dashaCalc.computeDashas(from: chart) == nil)
    }

    @Test("First dasha lord matches Moon nakshatra lord")
    func firstDashaLord() async throws {
        let chart = await computeJ2000Chart()
        let moonPos = chart.planets[.moon]!
        let (nakshatra, _) = Nakshatra.from(longitude: moonPos.longitude)
        let expectedLord = nakshatra.dashaLord

        let calc = VimshottariCalculator()
        let dashas = calc.computeDashas(from: chart)!
        #expect(dashas[0].planet == expectedLord)
    }

    @Test("Active dasha path returns 3 levels")
    func activeDashaPath() async throws {
        let chart = await computeJ2000Chart()
        let calc = VimshottariCalculator()
        let dashas = calc.computeDashas(from: chart, levels: 3)!

        // Use a date within the chart's dasha span
        let testDate = chart.birthData.dateTimeUTC.addingTimeInterval(365.25 * 86400 * 10) // 10 years later
        let path = calc.activeDashaPath(in: dashas, at: testDate)
        #expect(path.count == 3, "Should have Maha, Antar, Pratyantar")
        #expect(path[0].level == .maha)
        #expect(path[1].level == .antar)
        #expect(path[2].level == .pratyantar)
    }

    @Test("Swoven's current Maha-Antar-Pratyantar dasha")
    func swovenCurrentDasha() async throws {
        let birthData = BirthData.from(
            name: "Swoven Pokharel",
            year: 1985, month: 9, day: 10,
            hour: 0, minute: 45, second: 0,
            timeZoneID: "Asia/Kathmandu",
            latitude: 27.7172, longitude: 85.3240
        )
        let calcChart = ChartCalculator(ephemeris: await eph())
        let chart = await calcChart.computeChart(for: birthData)

        let calc = VimshottariCalculator()
        let dashas = calc.computeDashas(from: chart, levels: 3)!

        // Print all Maha Dashas with dates
        print("\n=== Swoven's Vimshottari Dasha ===")
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")

        for maha in dashas {
            print("\(maha.planet.rawValue) Maha Dasha: \(df.string(from: maha.startDate)) to \(df.string(from: maha.endDate))")
            for antar in maha.subPeriods {
                print("  \(maha.planet.rawValue)/\(antar.planet.rawValue): \(df.string(from: antar.startDate)) to \(df.string(from: antar.endDate))")
            }
        }

        // Find current dasha (use April 23, 2026 as "today")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2026, month: 4, day: 23))!

        let path = calc.activeDashaPath(in: dashas, at: today)
        #expect(path.count == 3)

        print("\nCurrent dasha on 2026-04-23:")
        print("  Maha: \(path[0].planet.rawValue)")
        print("  Antar: \(path[1].planet.rawValue)")
        print("  Pratyantar: \(path[2].planet.rawValue)")
    }

    @Test("Full Maha Dasha span is <= 120 years and consistent with balance")
    func fullSpan() async throws {
        let chart = await computeJ2000Chart()
        let calc = VimshottariCalculator()
        let dashas = calc.computeDashas(from: chart, levels: 1)!

        let firstStart = dashas.first!.startDate
        let lastEnd = dashas.last!.endDate
        let spanYears = lastEnd.timeIntervalSince(firstStart) / (365.25 * 86400)

        // Span = 120 years minus the elapsed portion of the first dasha
        let moonLon = chart.planets[.moon]!.longitude
        let fractionElapsed = Nakshatra.fractionElapsed(at: moonLon)
        let (nak, _) = Nakshatra.from(longitude: moonLon)
        let elapsedYears = fractionElapsed * nak.dashaLord.vimshottariYears
        let expectedSpan = 120.0 - elapsedYears

        #expect(spanYears > 0, "Span should be positive")
        #expect(spanYears <= 120.0, "Span should not exceed 120 years")
        #expect(abs(spanYears - expectedSpan) < 0.1, "Span should be ~\(expectedSpan) years, got \(spanYears)")
    }
}
