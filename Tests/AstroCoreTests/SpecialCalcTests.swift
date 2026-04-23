import Testing
@testable import AstroCore
import Foundation

@Suite("Ishta Devta, Arudha Lagna, Bhrigu Bindu", .serialized)
struct SpecialCalcTests {

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

    // MARK: - Karakamsa & Ishta Devta

    @Test("Ishta Devta computes with valid chart and karakas")
    func ishtaDevtaComputes() async throws {
        let chart = await swovenChart()
        let karakas = CharaKarakaCalculator().compute(from: chart)!
        let result = IshtaDevtaCalculator().compute(from: chart, karakas: karakas)

        #expect(result != nil)
        let ishta = result!
        #expect(ishta.atmakaraka == karakas.planet(for: .atmakaraka))
        #expect(ishta.akNavamsaSign == ishta.karakamsa.karakamsaSign)
    }

    @Test("Karakamsa sign is AK's Navamsa sign")
    func karakamsaIsAkNavamsa() async throws {
        let chart = await swovenChart()
        let karakas = CharaKarakaCalculator().compute(from: chart)!
        let result = IshtaDevtaCalculator().compute(from: chart, karakas: karakas)!

        // Verify Karakamsa = AK's D9 sign
        let ak = result.atmakaraka
        let akLong = chart.position(of: ak)!.longitude
        let expectedNavSign = Sign(rawValue: VargaType.d9.vargaSignIndex(for: akLong))!
        #expect(result.karakamsa.karakamsaSign == expectedNavSign)
    }

    @Test("12th from Karakamsa is one sign before")
    func twelfthFromKarakamsa() async throws {
        let chart = await swovenChart()
        let karakas = CharaKarakaCalculator().compute(from: chart)!
        let result = IshtaDevtaCalculator().compute(from: chart, karakas: karakas)!

        let expected = (result.karakamsa.karakamsaSign.rawValue + 11) % 12
        #expect(result.twelfthSign.rawValue == expected)
    }

    @Test("Deity maps correctly from significator planet")
    func deityMapping() {
        // Verify all planet-deity mappings are defined
        for planet in Planet.allCases {
            let deity = IshtaDevtaResult.Deity.from(planet: planet)
            #expect(!deity.rawValue.isEmpty)
        }
    }

    @Test("Ishta Devta returns nil without ascendant")
    func ishtaDevtaNoBirthTime() async throws {
        let birthData = BirthData(
            name: "No Time",
            dateTimeUTC: Date(),
            timeZoneOffset: 20700,
            latitude: 27.7172, longitude: 85.3240,
            hasBirthTime: false
        )
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)
        let karakas = CharaKarakaCalculator().compute(from: chart)
        // Without ascendant, karakas may still compute but IshtaDevta needs ascendant
        if let k = karakas {
            let result = IshtaDevtaCalculator().compute(from: chart, karakas: k)
            #expect(result == nil)
        }
    }

    // MARK: - Arudha Lagna

    @Test("Arudha Lagna computes all 12 houses")
    func arudhaLagnaAll12() async throws {
        let chart = await swovenChart()
        let result = ArudhaLagnaCalculator().compute(from: chart)

        #expect(result != nil)
        let arudha = result!
        #expect(arudha.arudhas.count == 12)
        for house in 1...12 {
            #expect(arudha.arudha(ofHouse: house) != nil,
                    "Arudha for house \(house) should exist")
        }
    }

    @Test("Pada Lagna (A1) and Upapada (A12) are accessible")
    func padaAndUpapada() async throws {
        let chart = await swovenChart()
        let result = ArudhaLagnaCalculator().compute(from: chart)!

        #expect(result.padaLagna != nil)
        #expect(result.upapadaLagna != nil)
        #expect(result.darapada != nil)
    }

    @Test("Arudha signs are valid (0–11 range)")
    func arudhaSignsValid() async throws {
        let chart = await swovenChart()
        let result = ArudhaLagnaCalculator().compute(from: chart)!

        for (_, sign) in result.arudhas {
            #expect(sign.rawValue >= 0 && sign.rawValue <= 11)
        }
    }

    @Test("Arudha Lagna returns nil without birth time")
    func arudhaLagnaNoBirthTime() async throws {
        let birthData = BirthData(
            name: "No Time",
            dateTimeUTC: Date(),
            timeZoneOffset: 20700,
            latitude: 27.7172, longitude: 85.3240,
            hasBirthTime: false
        )
        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)
        #expect(ArudhaLagnaCalculator().compute(from: chart) == nil)
    }

    @Test("Arudha Lagna is Codable")
    func arudhaLagnaCodable() async throws {
        let chart = await swovenChart()
        let result = ArudhaLagnaCalculator().compute(from: chart)!

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(ArudhaLagnaResult.self, from: data)
        #expect(decoded.arudhas.count == 12)
        #expect(decoded.padaLagna == result.padaLagna)
    }

    // MARK: - Bhrigu Bindu

    @Test("Bhrigu Bindu computes valid longitude")
    func bhriguBinduComputes() async throws {
        let chart = await swovenChart()
        let result = BhriguBinduCalculator().compute(from: chart)

        #expect(result != nil)
        let bb = result!
        #expect(bb.longitude >= 0 && bb.longitude < 360)
        #expect(bb.degreeInSign >= 0 && bb.degreeInSign < 30)
        #expect(bb.house != nil)
    }

    @Test("Bhrigu Bindu is midpoint of Moon and Rahu")
    func bhriguBinduIsMidpoint() async throws {
        let chart = await swovenChart()
        let moonLong = chart.position(of: .moon)!.longitude
        let rahuLong = chart.position(of: .rahu)!.longitude
        let bb = BhriguBinduCalculator().compute(from: chart)!

        // Verify BB is equidistant from Moon and Rahu (shorter arc)
        let distToMoon = shortArc(bb.longitude, moonLong)
        let distToRahu = shortArc(bb.longitude, rahuLong)
        #expect(abs(distToMoon - distToRahu) < 0.01,
                "BB should be equidistant from Moon and Rahu")
    }

    @Test("Bhrigu Bindu includes SAV score when provided")
    func bhriguBinduWithSAV() async throws {
        let chart = await swovenChart()
        let ashtakavarga = AshtakavargaCalculator().compute(from: chart)!
        let bb = BhriguBinduCalculator().compute(from: chart, ashtakavarga: ashtakavarga)!

        #expect(bb.savScore != nil)
        #expect(bb.savScore! > 0)
    }

    @Test("Bhrigu Bindu without SAV has nil score")
    func bhriguBinduNoSAV() async throws {
        let chart = await swovenChart()
        let bb = BhriguBinduCalculator().compute(from: chart)!
        #expect(bb.savScore == nil)
    }

    @Test("Bhrigu Bindu is Codable")
    func bhriguBinduCodable() async throws {
        let chart = await swovenChart()
        let bb = BhriguBinduCalculator().compute(from: chart)!

        let data = try JSONEncoder().encode(bb)
        let decoded = try JSONDecoder().decode(BhriguBinduResult.self, from: data)
        #expect(abs(decoded.longitude - bb.longitude) < 0.01)
        #expect(decoded.sign == bb.sign)
    }

    // MARK: - Print Summary

    @Test("Print Swoven's Ishta Devta, Arudha, and Bhrigu Bindu")
    func printAll() async throws {
        let chart = await swovenChart()
        let karakas = CharaKarakaCalculator().compute(from: chart)!
        let ishta = IshtaDevtaCalculator().compute(from: chart, karakas: karakas)!
        let arudha = ArudhaLagnaCalculator().compute(from: chart)!
        let ashtakavarga = AshtakavargaCalculator().compute(from: chart)!
        let bb = BhriguBinduCalculator().compute(from: chart, ashtakavarga: ashtakavarga)!

        print("\n=== KARAKAMSA & ISHTA DEVTA ===")
        print("Atmakaraka: \(ishta.atmakaraka.rawValue)")
        print("Karakamsa (AK in D9): \(ishta.karakamsa.karakamsaSign.name)")
        if let h = ishta.karakamsa.houseFromLagna {
            print("Karakamsa House from Lagna: H\(h)")
        }
        if !ishta.karakamsa.planetsInKarakamsa.isEmpty {
            print("Planets in Karakamsa: \(ishta.karakamsa.planetsInKarakamsa.map { $0.rawValue }.joined(separator: ", "))")
        }
        print("12th from Karakamsa: \(ishta.twelfthSign.name)")
        if !ishta.planetsInTwelfth.isEmpty {
            print("Planets in 12th: \(ishta.planetsInTwelfth.map { $0.rawValue }.joined(separator: ", "))")
        }
        print("Significator: \(ishta.significator.rawValue)")
        print("Ishta Devta: \(ishta.deity.rawValue)")

        print("\n=== ARUDHA LAGNAS ===")
        let labels = [
            1: "AL", 2: "A2", 3: "A3", 4: "A4", 5: "A5", 6: "A6",
            7: "A7", 8: "A8", 9: "A9", 10: "A10", 11: "A11", 12: "UL"
        ]
        for house in 1...12 {
            let sign = arudha.arudha(ofHouse: house)!
            print("  H\(String(format: "%2d", house)) (\(labels[house]!.padding(toLength: 3, withPad: " ", startingAt: 0))): \(sign.name)")
        }

        print("\n=== BHRIGU BINDU ===")
        print("Position: \(bb.formattedPosition)")
        print("Nakshatra: \(bb.nakshatra.name) Pada \(bb.pada)")
        if let h = bb.house { print("House: H\(h)") }
        if let sav = bb.savScore { print("SAV Score at sign: \(sav)") }
    }

    // MARK: - Helper

    private func shortArc(_ a: Double, _ b: Double) -> Double {
        var diff = abs(a - b)
        if diff > 180 { diff = 360 - diff }
        return diff
    }
}
