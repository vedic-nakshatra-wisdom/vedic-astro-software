import Testing
@testable import AstroCore
import Foundation

@Suite("ShadBala Tests", .serialized)
struct ShadBalaTests {

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

    // MARK: - Basic Computation

    @Test("Compute Shadbala for all 7 planets")
    func computeAll() async throws {
        let chart = await swovenChart()
        let calc = ShadBalaCalculator()
        let result = calc.compute(from: chart)

        #expect(result != nil)
        let shadbala = result!
        #expect(shadbala.planetBala.count == 7)

        for planet in Planet.signLords {
            #expect(shadbala.planetBala[planet] != nil,
                    "\(planet.rawValue) should have Shadbala")
        }
    }

    @Test("Rahu and Ketu excluded from Shadbala")
    func nodesExcluded() async throws {
        let chart = await swovenChart()
        let calc = ShadBalaCalculator()
        let result = calc.compute(from: chart)!

        #expect(result.planetBala[.rahu] == nil)
        #expect(result.planetBala[.ketu] == nil)
    }

    @Test("Returns nil without birth time")
    func noBirthTime() async throws {
        let birthData = BirthData(
            name: "No Time",
            dateTimeUTC: Date(),
            timeZoneOffset: 20700,
            latitude: 27.7172, longitude: 85.3240,
            hasBirthTime: false
        )
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)
        let shadCalc = ShadBalaCalculator()
        #expect(shadCalc.compute(from: chart) == nil)
    }

    // MARK: - Uchcha Bala

    @Test("Uchcha Bala range: 0–60 virupas")
    func uchchaBalaRange() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        for (_, bala) in result.planetBala {
            #expect(bala.uchchaBala >= 0 && bala.uchchaBala <= 60,
                    "\(bala.planet.rawValue) Uchcha Bala \(bala.uchchaBala) out of range")
        }
    }

    // MARK: - Kendradi Bala

    @Test("Kendradi Bala is 60, 30, or 15")
    func kendradiBalaValues() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        let valid: Set<Double> = [60.0, 30.0, 15.0]
        for (_, bala) in result.planetBala {
            #expect(valid.contains(bala.kendradiBala),
                    "\(bala.planet.rawValue) Kendradi Bala \(bala.kendradiBala) invalid")
        }
    }

    // MARK: - Drekkana Bala

    @Test("Drekkana Bala is 0 or 15")
    func drekkanaBalaValues() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        for (_, bala) in result.planetBala {
            #expect(bala.drekkanaBala == 0.0 || bala.drekkanaBala == 15.0,
                    "\(bala.planet.rawValue) Drekkana Bala \(bala.drekkanaBala) invalid")
        }
    }

    // MARK: - Ojhayugmarasi Bala

    @Test("Ojhayugmarasi Bala range: 0–30")
    func ojhayugmasiBalaRange() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        let valid: Set<Double> = [0.0, 15.0, 30.0]
        for (_, bala) in result.planetBala {
            #expect(valid.contains(bala.ojhayugmarasiBala),
                    "\(bala.planet.rawValue) Ojhayugmarasi \(bala.ojhayugmarasiBala) invalid")
        }
    }

    // MARK: - Dig Bala

    @Test("Dig Bala range: 0–60 virupas")
    func digBalaRange() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        for (_, bala) in result.planetBala {
            #expect(bala.digBala >= 0 && bala.digBala <= 60,
                    "\(bala.planet.rawValue) Dig Bala \(bala.digBala) out of range")
        }
    }

    // MARK: - Naisargika Bala

    @Test("Naisargika Bala: Sun strongest, Saturn weakest")
    func naisargikaOrder() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        let sun = result.planetBala[.sun]!.naisargikaBala
        let saturn = result.planetBala[.saturn]!.naisargikaBala
        #expect(sun == 60.0)
        #expect(saturn == 8.57)
        #expect(sun > saturn)
    }

    // MARK: - Paksha Bala

    @Test("Paksha Bala range: 0–60 virupas")
    func pakshaBalaRange() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        for (_, bala) in result.planetBala {
            let maxPaksha: Double = bala.planet == .moon ? 120.0 : 60.0
            #expect(bala.pakshaBala >= 0 && bala.pakshaBala <= maxPaksha,
                    "\(bala.planet.rawValue) Paksha Bala \(bala.pakshaBala) out of range")
        }
    }

    // MARK: - Totals

    @Test("Total virupas are positive and total rupas = virupas/60")
    func totalsConsistency() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        for (_, bala) in result.planetBala {
            #expect(bala.totalVirupas > 0)
            #expect(abs(bala.totalRupas - bala.totalVirupas / 60.0) < 0.001)
            let sum = bala.sthanaBala + bala.digBala + bala.kalaBala + bala.cheshtaBala + bala.naisargikaBala + bala.drikBala
            #expect(abs(sum - bala.totalVirupas) < 0.01)
        }
    }

    @Test("Strongest and weakest are different planets")
    func strongestWeakest() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        #expect(result.strongest != nil)
        #expect(result.weakest != nil)
        #expect(result.strongest != result.weakest)
    }

    // MARK: - Codable

    @Test("ShadBalaResult round-trips through JSON")
    func codableRoundTrip() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ShadBalaResult.self, from: data)

        #expect(decoded.planetBala.count == result.planetBala.count)
        for planet in Planet.signLords {
            let orig = result.planetBala[planet]!
            let dec = decoded.planetBala[planet]!
            #expect(abs(orig.totalVirupas - dec.totalVirupas) < 0.01)
        }
    }

    // MARK: - Print Summary

    @Test("Print Swoven's Shadbala for visual verification")
    func printSwovenShadbala() async throws {
        let chart = await swovenChart()
        let result = ShadBalaCalculator().compute(from: chart)!

        print("\n=== SHADBALA (Six-fold Strength) — Full Implementation ===\n")

        let order: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]

        print("--- STHANA BALA ---")
        print("Planet    | Uchcha | SaptaV | Ojha | Kendra | Drekk | Total")
        print(String(repeating: "-", count: 70))
        for planet in order {
            let b = result.planetBala[planet]!
            print(String(format: "%-9s | %5.1f  | %5.1f  | %4.0f | %5.0f   | %4.0f  | %5.1f",
                         (planet.rawValue as NSString).utf8String!,
                         b.uchchaBala, b.saptavargajaBala, b.ojhayugmarasiBala,
                         b.kendradiBala, b.drekkanaBala, b.sthanaBala))
        }

        print("\n--- DIG BALA ---")
        for planet in order {
            let b = result.planetBala[planet]!
            print(String(format: "%-9s | %5.1f", (planet.rawValue as NSString).utf8String!, b.digBala))
        }

        print("\n--- KALA BALA ---")
        print("Planet    | Paksha | Naton | Tribh | Abda | Masa | Vara | Hora | Ayana | Total")
        print(String(repeating: "-", count: 90))
        for planet in order {
            let b = result.planetBala[planet]!
            print(String(format: "%-9s | %5.1f  | %4.1f  | %4.0f  | %3.0f  | %3.0f  | %3.0f  | %3.0f  | %4.1f  | %5.1f",
                         (planet.rawValue as NSString).utf8String!,
                         b.pakshaBala, b.natonnathaBala,
                         b.tribhagaBala, b.abdaBala, b.masaBala,
                         b.varaBala, b.horaBala, b.ayanaBala, b.kalaBala))
        }

        print("\n--- NAISARGIKA BALA (Natural Strength) ---")
        for planet in order {
            let b = result.planetBala[planet]!
            print(String(format: "%-9s | %5.2f",
                         (planet.rawValue as NSString).utf8String!, b.naisargikaBala))
        }

        print("\n--- CHESHTA & DRIK BALA ---")
        for planet in order {
            let b = result.planetBala[planet]!
            print(String(format: "%-9s | Cheshta: %5.1f | Drik: %6.1f",
                         (planet.rawValue as NSString).utf8String!, b.cheshtaBala, b.drikBala))
        }

        print("\n--- TOTALS ---")
        print("Planet    | Sthana | Dig   | Kala  | Chesh | Naisr | Drik  | TOTAL  | Rupas  | Min  | Met?")
        print(String(repeating: "-", count: 105))
        for planet in order {
            let b = result.planetBala[planet]!
            let minR = ShadBalaResult.minimumRupas[planet]!
            let met = result.meetsMinimum(planet)! ? "YES" : "NO"
            let line = String(format: "%-9s | %5.1f  | %4.1f  | %5.1f | %4.1f  | %4.1f | %5.1f | %6.1f | %5.2f  | %4.1f | ",
                         (planet.rawValue as NSString).utf8String!,
                         b.sthanaBala, b.digBala, b.kalaBala,
                         b.cheshtaBala, b.naisargikaBala, b.drikBala,
                         b.totalVirupas, b.totalRupas, minR)
            print(line + met)
        }

        print("\nIshta / Kashta Phala:")
        for planet in order {
            let b = result.planetBala[planet]!
            print(String(format: "%-9s | Ishta: %5.1f | Kashta: %5.1f",
                         (planet.rawValue as NSString).utf8String!, b.ishtaPhala, b.kashtaPhala))
        }

        print("\nStrongest: \(result.strongest!.rawValue)")
        print("Weakest:   \(result.weakest!.rawValue)")
    }
}
