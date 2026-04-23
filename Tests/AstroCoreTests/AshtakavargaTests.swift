import Testing
@testable import AstroCore
import Foundation

@Suite("Ashtakavarga", .serialized)
struct AshtakavargaTests {

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

    // MARK: - Data validation

    @Test("BPHS tables have all 7 planets")
    func tablesComplete() {
        #expect(AshtakavargaData.tables.count == 7)
        for planet in Planet.ashtakavargaPlanets {
            #expect(AshtakavargaData.tables[planet] != nil, "\(planet.rawValue) table missing")
        }
    }

    @Test("Each planet table has 8 contributors")
    func eightContributors() {
        for (planet, table) in AshtakavargaData.tables {
            #expect(table.count == 8, "\(planet.rawValue) should have 8 contributors")
        }
    }

    @Test("Bindu counts per planet match BPHS invariants")
    func binduTotals() {
        // Count total benefic houses per planet across all contributors
        for (planet, table) in AshtakavargaData.tables {
            var total = 0
            for (_, houses) in table {
                total += houses.count
            }
            let expected = AshtakavargaData.expectedTotals[planet]!
            #expect(total == expected, "\(planet.rawValue) should have \(expected) total bindus, got \(total)")
        }
    }

    @Test("All house numbers are 1-12")
    func validHouseNumbers() {
        for (planet, table) in AshtakavargaData.tables {
            for (contributor, houses) in table {
                for house in houses {
                    #expect(house >= 1 && house <= 12,
                            "\(planet.rawValue) from \(contributor): invalid house \(house)")
                }
            }
        }
    }

    // MARK: - Computation tests

    @Test("BAV bindus per sign range from 0 to 8")
    func bavBinduRange() async throws {
        let chart = await j2000Chart()
        let calc = AshtakavargaCalculator()
        let result = calc.compute(from: chart)!

        for (planet, bav) in result.bpiBindus {
            for (i, bindu) in bav.bindus.enumerated() {
                #expect(bindu >= 0 && bindu <= 8,
                        "\(planet.rawValue) sign \(i): bindu \(bindu) out of range")
            }
        }
    }

    @Test("BAV totals match BPHS invariants for any chart")
    func bavTotalsInvariant() async throws {
        let chart = await j2000Chart()
        let calc = AshtakavargaCalculator()
        let result = calc.compute(from: chart)!

        for planet in Planet.ashtakavargaPlanets {
            let bav = result.bpiBindus[planet]!
            let expected = AshtakavargaData.expectedTotals[planet]!
            #expect(bav.total == expected,
                    "\(planet.rawValue) BAV total should be \(expected), got \(bav.total)")
        }
    }

    @Test("SAV total is always 337")
    func savTotal337() async throws {
        let chart = await j2000Chart()
        let calc = AshtakavargaCalculator()
        let result = calc.compute(from: chart)!

        #expect(result.sarvashtakavarga.total == 337,
                "SAV total should be 337, got \(result.sarvashtakavarga.total)")
    }

    @Test("SAV equals sum of all BAVs per sign")
    func savEqualsBavSum() async throws {
        let chart = await j2000Chart()
        let calc = AshtakavargaCalculator()
        let result = calc.compute(from: chart)!

        for i in 0..<12 {
            var sum = 0
            for planet in Planet.ashtakavargaPlanets {
                sum += result.bpiBindus[planet]!.bindus[i]
            }
            #expect(sum == result.sarvashtakavarga.bindus[i],
                    "SAV[\(i)] should be \(sum), got \(result.sarvashtakavarga.bindus[i])")
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
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)
        let ashCalc = AshtakavargaCalculator()
        #expect(ashCalc.compute(from: chart) == nil)
    }

    @Test("BAV totals invariant for Swoven's chart too")
    func swovenBavTotals() async throws {
        let chart = await swovenChart()
        let calc = AshtakavargaCalculator()
        let result = calc.compute(from: chart)!

        for planet in Planet.ashtakavargaPlanets {
            let bav = result.bpiBindus[planet]!
            let expected = AshtakavargaData.expectedTotals[planet]!
            #expect(bav.total == expected)
        }
        #expect(result.sarvashtakavarga.total == 337)
    }

    @Test("Swoven's Ashtakavarga -- compute and print")
    func swovenAshtakavarga() async throws {
        let chart = await swovenChart()
        let calc = AshtakavargaCalculator()
        let result = calc.compute(from: chart)!

        print("\n=== Swoven's Ashtakavarga ===")
        result.printSummary()

        // Basic sanity: all 7 planets computed
        #expect(result.bpiBindus.count == 7)
        #expect(result.sarvashtakavarga.bindus.count == 12)
    }

    @Test("Bhinnashtakavarga is Codable")
    func bavCodable() async throws {
        let chart = await j2000Chart()
        let calc = AshtakavargaCalculator()
        let result = calc.compute(from: chart)!

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        let decoded = try JSONDecoder().decode(AshtakavargaResult.self, from: data)

        #expect(decoded.sarvashtakavarga.total == 337)
        for planet in Planet.ashtakavargaPlanets {
            #expect(decoded.bpiBindus[planet]!.total == result.bpiBindus[planet]!.total)
        }
    }
}
