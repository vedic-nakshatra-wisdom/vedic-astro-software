import Testing
@testable import AstroCore
import CSwissEph
import Foundation

@Suite("ChartCalculator – D1 birth chart computation", .serialized)
struct ChartCalculatorTests {

    private func eph() async -> EphemerisActor {
        await TestEphemeris.initialize()
        return TestEphemeris.shared
    }

    /// Swami Vivekananda: January 12, 1863, 6:33 AM LMT, Kolkata (22.5726N, 88.3639E)
    /// Pre-standardized timezone era — uses explicit LMT offset (+5:53:28 = +5.8911h)
    private func vivekanandaBirthData() -> BirthData {
        BirthData.from(
            name: "Swami Vivekananda",
            year: 1863, month: 1, day: 12,
            hour: 6, minute: 33, second: 0,
            timeZoneHours: 5.8911,
            latitude: 22.5726,
            longitude: 88.3639
        )
    }

    /// J2000 epoch data (2000-01-01 12:00 UTC, lat 0, lon 0)
    private func j2000BirthData() -> BirthData {
        BirthData.from(
            name: "J2000 Epoch",
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneHours: 0.0,
            latitude: 0.0,
            longitude: 0.0
        )
    }

    // MARK: - Basic chart computation

    @Test("All 9 planets are computed")
    func allPlanetsComputed() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: j2000BirthData())

        #expect(chart.planets.count == 9, "Should have all 9 Vedic planets")
        for planet in Planet.allCases {
            #expect(chart.planets[planet] != nil, "\(planet.rawValue) should be present")
        }
    }

    @Test("Ascendant is computed when birth time is known")
    func ascendantComputed() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: j2000BirthData())

        #expect(chart.ascendant != nil, "Ascendant should be computed")
        #expect(chart.ascendant!.longitude >= 0.0)
        #expect(chart.ascendant!.longitude < 360.0)
    }

    @Test("12 house cusps are computed")
    func houseCuspsComputed() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: j2000BirthData())

        #expect(chart.houseCusps != nil, "House cusps should be computed")
        #expect(chart.houseCusps!.count == 12, "Should have 12 cusps")
        for cusp in chart.houseCusps! {
            #expect(cusp >= 0.0 && cusp < 360.0, "Cusp should be 0-360")
        }
    }

    @Test("Ketu is 180 degrees from Rahu")
    func ketuOppositeRahu() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: j2000BirthData())

        let rahu = chart.planets[.rahu]!
        let ketu = chart.planets[.ketu]!

        let diff = abs(rahu.longitude - ketu.longitude)
        let separation = min(diff, 360.0 - diff)
        #expect(abs(separation - 180.0) < 0.001, "Ketu should be exactly 180 from Rahu")
    }

    @Test("Ayanamsa value is reasonable for J2000")
    func ayanamsaReasonable() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: j2000BirthData())

        #expect(chart.ayanamsaValue > 23.8, "Lahiri ayanamsa should be > 23.8")
        #expect(chart.ayanamsaValue < 23.9, "Lahiri ayanamsa should be < 23.9")
    }

    // MARK: - Known chart: Swami Vivekananda

    @Test("Vivekananda: Lagna in Sagittarius")
    func vivekanandaLagna() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: vivekanandaBirthData())

        #expect(chart.lagnaSign == .sagittarius, "Vivekananda lagna should be Sagittarius")
    }

    @Test("Vivekananda: Sun in Sagittarius")
    func vivekanandaSun() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: vivekanandaBirthData())

        let sun = chart.planets[.sun]!
        #expect(sun.sign == .sagittarius, "Vivekananda Sun should be in Sagittarius, got \(sun.sign.name)")
    }

    @Test("Vivekananda: Moon position is valid")
    func vivekanandaMoon() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: vivekanandaBirthData())

        let moon = chart.planets[.moon]!
        #expect(moon.longitude >= 0.0 && moon.longitude < 360.0,
                "Moon longitude should be valid")
        print("Vivekananda Moon: \(moon.shortDescription)")
    }

    // MARK: - No birth time

    @Test("No birth time: ascendant and cusps are nil")
    func noBirthTime() async throws {
        let birthData = BirthData(
            name: "Unknown Time",
            dateTimeUTC: Date(timeIntervalSince1970: 946728000),
            timeZoneOffset: 0,
            latitude: 0,
            longitude: 0,
            hasBirthTime: false
        )

        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)

        #expect(chart.ascendant == nil, "Ascendant should be nil without birth time")
        #expect(chart.houseCusps == nil, "House cusps should be nil without birth time")
        #expect(chart.planets.count == 9, "Planets should still be computed")
    }

    // MARK: - J2000 reference values

    @Test("J2000 Sun sidereal longitude matches spike test range")
    func j2000SunPosition() async throws {
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: j2000BirthData())

        let sun = chart.planets[.sun]!
        #expect(sun.longitude > 250.0, "Sun sidereal longitude should be > 250")
        #expect(sun.longitude < 265.0, "Sun sidereal longitude should be < 265")
    }
}
