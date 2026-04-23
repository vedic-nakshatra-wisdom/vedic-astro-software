import Testing
@testable import AstroCore
import Foundation

@Suite("Swoven's Birth Chart", .serialized)
struct SwovenChartTest {

    private func eph() async -> EphemerisActor {
        await TestEphemeris.initialize()
        return TestEphemeris.shared
    }

    @Test("Nepal 1985 resolves to UTC+5:30, not UTC+5:45")
    func nepalHistoricalTimezone() async throws {
        // Nepal used IST (UTC+5:30) until 1986-01-01
        let pre1986 = BirthData.from(
            name: "Pre-1986 Nepal",
            year: 1985, month: 9, day: 10,
            hour: 0, minute: 45, second: 0,
            timeZoneID: "Asia/Kathmandu",
            latitude: 27.7172, longitude: 85.3240
        )
        #expect(pre1986.timeZoneOffset == 19800, // +5:30 = 19800 seconds
                "Nepal in 1985 should be UTC+5:30 (19800s), got \(pre1986.timeZoneOffset)")

        // After 1986-01-01, Nepal is UTC+5:45
        let post1986 = BirthData.from(
            name: "Post-1986 Nepal",
            year: 1986, month: 6, day: 15,
            hour: 12, minute: 0, second: 0,
            timeZoneID: "Asia/Kathmandu",
            latitude: 27.7172, longitude: 85.3240
        )
        #expect(post1986.timeZoneOffset == 20700, // +5:45 = 20700 seconds
                "Nepal after 1986 should be UTC+5:45 (20700s), got \(post1986.timeZoneOffset)")
    }

    @Test("Compute and print Swoven's D1 chart")
    func swovenChart() async throws {
        // Uses IANA timezone — auto-resolves to UTC+5:30 for Sept 1985
        let birthData = BirthData.from(
            name: "Swoven Pokharel",
            year: 1985, month: 9, day: 10,
            hour: 0, minute: 45, second: 0,
            timeZoneID: "Asia/Kathmandu",
            latitude: 27.7172,
            longitude: 85.3240
        )

        // Verify the offset resolved correctly
        #expect(birthData.timeZoneOffset == 19800, "Should use IST +5:30 for 1985 Nepal")

        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)

        chart.printSummary()

        #expect(chart.planets.count == 9)
        #expect(chart.ascendant != nil)
        #expect(chart.houseCusps != nil)

        print("\n--- House Cusps ---")
        if let cusps = chart.houseCusps {
            for (i, cusp) in cusps.enumerated() {
                let sign = Sign.from(longitude: cusp)
                print("  House \(i + 1): \(sign.name) \(String(format: "%.2f", cusp))°")
            }
        }

        // Print all 16 vargas
        print("\n" + String(repeating: "=", count: 50))
        print("SHODASHA VARGA (16 Divisional Charts)")
        print(String(repeating: "=", count: 50))

        let vargaCalc = VargaCalculator()
        let allVargas = vargaCalc.computeAllVargas(from: chart)

        for varga in VargaType.allCases {
            if let vc = allVargas[varga] {
                print("")
                vc.printSummary()
            }
        }
    }
}
