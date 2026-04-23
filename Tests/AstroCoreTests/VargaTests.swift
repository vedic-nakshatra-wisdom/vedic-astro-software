import Testing
@testable import AstroCore
import Foundation

@Suite("Shodasha Varga – 16 Divisional Charts", .serialized)
struct VargaTests {

    private func eph() async -> EphemerisActor {
        await TestEphemeris.initialize()
        return TestEphemeris.shared
    }

    // MARK: - A) Unit tests for VargaType.vargaSignIndex

    // Test longitude: 256.516° (Sun at Sag 16°31')
    // signIndex = 8 (Sagittarius), degInSign = 16.516°

    @Test("D1: Sagittarius longitude returns Sagittarius")
    func d1Sagittarius() {
        #expect(VargaType.d1.vargaSignIndex(for: 256.516) == 8)
    }

    @Test("D2 Hora: Sag 16.516° (odd sign, deg >= 15) → Cancer")
    func d2Sagittarius() {
        #expect(VargaType.d2.vargaSignIndex(for: 256.516) == 3)
    }

    @Test("D3 Drekkana: Sag 16.516° → Aries")
    func d3Sagittarius() {
        // compartment 1 (10-20°), 5th from Sag: (8+4)%12 = 0 = Aries
        #expect(VargaType.d3.vargaSignIndex(for: 256.516) == 0)
    }

    @Test("D4 Chaturthamsa: Sag 16.516° → Gemini")
    func d4Sagittarius() {
        // compartment 2 (15-22.5°), 7th from Sag: (8+6)%12 = 2 = Gemini
        #expect(VargaType.d4.vargaSignIndex(for: 256.516) == 2)
    }

    @Test("D7 Saptamsa: Sag 16.516° → Pisces")
    func d7Sagittarius() {
        // compartment = floor(16.516 / 4.2857) = 3, odd: (8+3)%12 = 11 = Pisces
        #expect(VargaType.d7.vargaSignIndex(for: 256.516) == 11)
    }

    @Test("D9 Navamsa: Sag 16.516° → Leo")
    func d9Sagittarius() {
        // compartment = floor(16.516 / 3.333) = 4, fire: start=0, (0+4)%12 = 4 = Leo
        #expect(VargaType.d9.vargaSignIndex(for: 256.516) == 4)
    }

    @Test("D10 Dasamsa: Sag 16.516° → Taurus")
    func d10Sagittarius() {
        // compartment = floor(16.516 / 3) = 5, odd: (8+5)%12 = 1 = Taurus
        #expect(VargaType.d10.vargaSignIndex(for: 256.516) == 1)
    }

    @Test("D12 Dwadasamsa: Sag 16.516° → Gemini")
    func d12Sagittarius() {
        // compartment = floor(16.516 / 2.5) = 6, (8+6)%12 = 2 = Gemini
        #expect(VargaType.d12.vargaSignIndex(for: 256.516) == 2)
    }

    // Test longitude: 199.471° (Moon at Lib 19°28')
    // signIndex = 6 (Libra), degInSign = 19.471°

    @Test("D1: Libra longitude returns Libra")
    func d1Libra() {
        #expect(VargaType.d1.vargaSignIndex(for: 199.471) == 6)
    }

    @Test("D2 Hora: Lib 19.471° (odd sign, deg >= 15) → Cancer")
    func d2Libra() {
        // Libra (rawValue=6) is odd (6 % 2 == 0), deg >= 15 → Cancer(3)
        #expect(VargaType.d2.vargaSignIndex(for: 199.471) == 3)
    }

    @Test("D3 Drekkana: Lib 19.471° → Aquarius")
    func d3Libra() {
        // compartment 1 (10-20°), 5th from Libra: (6+4)%12 = 10 = Aquarius
        #expect(VargaType.d3.vargaSignIndex(for: 199.471) == 10)
    }

    @Test("D9 Navamsa: Lib 19.471° → Pisces")
    func d9Libra() {
        // compartment = floor(19.471/3.333) = 5, air: start=6, (6+5)%12 = 11 = Pisces
        #expect(VargaType.d9.vargaSignIndex(for: 199.471) == 11)
    }

    // MARK: - D30 Trimsamsa specific tests

    @Test("D30: odd sign boundaries")
    func d30OddSign() {
        // Aries = signIndex 0, longitude = 0 + degInSign
        #expect(VargaType.d30.vargaSignIndex(for: 3.0) == 0)   // Aries (Mars 0-5)
        #expect(VargaType.d30.vargaSignIndex(for: 7.0) == 10)  // Aquarius (Saturn 5-10)
        #expect(VargaType.d30.vargaSignIndex(for: 14.0) == 8)  // Sagittarius (Jupiter 10-18)
        #expect(VargaType.d30.vargaSignIndex(for: 22.0) == 2)  // Gemini (Mercury 18-25)
        #expect(VargaType.d30.vargaSignIndex(for: 27.0) == 6)  // Libra (Venus 25-30)
    }

    @Test("D30: even sign boundaries")
    func d30EvenSign() {
        // Taurus = signIndex 1, longitude = 30 + degInSign
        #expect(VargaType.d30.vargaSignIndex(for: 33.0) == 1)  // Taurus (Venus 0-5)
        #expect(VargaType.d30.vargaSignIndex(for: 38.0) == 5)  // Virgo (Mercury 5-12)
        #expect(VargaType.d30.vargaSignIndex(for: 46.0) == 11) // Pisces (Jupiter 12-20)
        #expect(VargaType.d30.vargaSignIndex(for: 52.0) == 9)  // Capricorn (Saturn 20-25)
        #expect(VargaType.d30.vargaSignIndex(for: 57.0) == 7)  // Scorpio (Mars 25-30)
    }

    // MARK: - Additional varga formula tests

    @Test("D16 Shodasamsa: movable, fixed, dual start signs")
    func d16QualityStart() {
        // Aries (movable, 0): compartment 0 → start=0 → Aries(0)
        #expect(VargaType.d16.vargaSignIndex(for: 0.5) == 0)
        // Taurus (fixed, 1): compartment 0 → start=4 → Leo(4)
        #expect(VargaType.d16.vargaSignIndex(for: 30.5) == 4)
        // Gemini (dual, 2): compartment 0 → start=8 → Sagittarius(8)
        #expect(VargaType.d16.vargaSignIndex(for: 60.5) == 8)
    }

    @Test("D20 Vimsamsa: quality-based starts")
    func d20QualityStart() {
        // Aries (movable): compartment 0 → start=0 → Aries(0)
        #expect(VargaType.d20.vargaSignIndex(for: 0.5) == 0)
        // Taurus (fixed): compartment 0 → start=8 → Sagittarius(8)
        #expect(VargaType.d20.vargaSignIndex(for: 30.5) == 8)
        // Gemini (dual): compartment 0 → start=4 → Leo(4)
        #expect(VargaType.d20.vargaSignIndex(for: 60.5) == 4)
    }

    @Test("D24 Siddhamsa: odd/even start signs")
    func d24OddEvenStart() {
        // Aries (odd): compartment 0 → start=4 → Leo(4)
        #expect(VargaType.d24.vargaSignIndex(for: 0.5) == 4)
        // Taurus (even): compartment 0 → start=3 → Cancer(3)
        #expect(VargaType.d24.vargaSignIndex(for: 30.5) == 3)
    }

    @Test("D27 Bhamsa: element-based starts")
    func d27ElementStart() {
        // Aries (fire): compartment 0 → start=0 → Aries(0)
        #expect(VargaType.d27.vargaSignIndex(for: 0.5) == 0)
        // Taurus (earth): compartment 0 → start=3 → Cancer(3)
        #expect(VargaType.d27.vargaSignIndex(for: 30.5) == 3)
        // Gemini (air): compartment 0 → start=6 → Libra(6)
        #expect(VargaType.d27.vargaSignIndex(for: 60.5) == 6)
        // Cancer (water): compartment 0 → start=9 → Capricorn(9)
        #expect(VargaType.d27.vargaSignIndex(for: 90.5) == 9)
    }

    @Test("D40 Khavedamsa: odd/even start signs")
    func d40OddEvenStart() {
        // Aries (odd): compartment 0 → start=0 → Aries(0)
        #expect(VargaType.d40.vargaSignIndex(for: 0.25) == 0)
        // Taurus (even): compartment 0 → start=6 → Libra(6)
        #expect(VargaType.d40.vargaSignIndex(for: 30.25) == 6)
    }

    @Test("D45 Akshavedamsa: quality-based starts")
    func d45QualityStart() {
        // Aries (movable): compartment 0 → start=0 → Aries(0)
        #expect(VargaType.d45.vargaSignIndex(for: 0.25) == 0)
        // Taurus (fixed): compartment 0 → start=4 → Leo(4)
        #expect(VargaType.d45.vargaSignIndex(for: 30.25) == 4)
        // Gemini (dual): compartment 0 → start=8 → Sagittarius(8)
        #expect(VargaType.d45.vargaSignIndex(for: 60.25) == 8)
    }

    @Test("D60 Shashtiamsa: wraps through zodiac")
    func d60Shashtiamsa() {
        // Aries 0.25°: compartment = 0, (0 + 0%12) % 12 = 0 = Aries
        #expect(VargaType.d60.vargaSignIndex(for: 0.25) == 0)
        // Aries 6.25°: compartment = 12, (0 + 12%12) % 12 = 0 = Aries (wraps)
        #expect(VargaType.d60.vargaSignIndex(for: 6.25) == 0)
        // Aries 3.25°: compartment = 6, (0 + 6%12) % 12 = 6 = Libra
        #expect(VargaType.d60.vargaSignIndex(for: 3.25) == 6)
    }

    // MARK: - B) Integration: Swoven's Navamsa

    @Test("Swoven's Navamsa (D9) chart computes and prints")
    func swovenNavamsa() async throws {
        let birthData = BirthData.from(
            name: "Swoven Pokharel",
            year: 1985, month: 9, day: 10,
            hour: 0, minute: 45, second: 0,
            timeZoneID: "Asia/Kathmandu",
            latitude: 27.7172,
            longitude: 85.3240
        )

        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)
        let vargaCalc = VargaCalculator()
        let navamsa = vargaCalc.computeVarga(.d9, from: chart)

        navamsa.printSummary()

        // Verify all 9 planets have placements
        for planet in Planet.allCases {
            #expect(navamsa.sign(of: planet) != nil, "\(planet.rawValue) should have a D9 placement")
        }
        // Ascendant should be computed
        #expect(navamsa.ascendantSign != nil, "D9 ascendant should be computed")
    }

    // MARK: - C) Integration: All 16 vargas for J2000

    @Test("All 16 vargas compute valid results for J2000")
    func allVargasJ2000() async throws {
        let birthData = BirthData.from(
            name: "J2000 Epoch",
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneHours: 0.0,
            latitude: 0.0,
            longitude: 0.0
        )

        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)
        let vargaCalc = VargaCalculator()
        let allVargas = vargaCalc.computeAllVargas(from: chart)

        #expect(allVargas.count == 16, "Should have all 16 vargas")

        for vargaType in VargaType.allCases {
            let varga = allVargas[vargaType]
            #expect(varga != nil, "\(vargaType.name) should be computed")
            #expect(varga!.placements.count == 9, "\(vargaType.name) should have 9 planet placements")
            #expect(varga!.ascendantSign != nil, "\(vargaType.name) should have ascendant")

            // Print each varga
            varga!.printSummary()
            print("")
        }
    }

    // MARK: - D) D1 returns same signs as original chart

    @Test("D1 varga returns same signs as source chart")
    func d1MatchesSourceChart() async throws {
        let birthData = BirthData.from(
            name: "J2000 Epoch",
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneHours: 0.0,
            latitude: 0.0,
            longitude: 0.0
        )

        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)
        let vargaCalc = VargaCalculator()
        let d1 = vargaCalc.computeVarga(.d1, from: chart)

        for planet in Planet.allCases {
            let originalSign = chart.planets[planet]!.sign
            let d1Sign = d1.sign(of: planet)
            #expect(d1Sign == originalSign,
                    "\(planet.rawValue): D1 sign \(d1Sign?.name ?? "nil") should match source \(originalSign.name)")
        }

        if let asc = chart.ascendant {
            #expect(d1.ascendantSign == asc.sign,
                    "D1 ascendant should match source chart ascendant")
        }
    }

    // MARK: - E) Boundary tests

    @Test("Boundary: 0° longitude → Aries for D1")
    func boundary0Degrees() {
        #expect(VargaType.d1.vargaSignIndex(for: 0.0) == 0)
    }

    @Test("Boundary: just before 30° stays in Aries for D1")
    func boundaryJustBefore30() {
        #expect(VargaType.d1.vargaSignIndex(for: 29.999) == 0)
    }

    @Test("Boundary: exactly 30° → Taurus for D1")
    func boundaryExactly30() {
        #expect(VargaType.d1.vargaSignIndex(for: 30.0) == 1)
    }

    @Test("Boundary: 360° wraps to Aries for D1")
    func boundary360Degrees() {
        #expect(VargaType.d1.vargaSignIndex(for: 360.0) == 0)
    }

    @Test("Boundary: D9 at exact sign boundary 0°")
    func d9AtZero() {
        // Aries 0°: compartment=0, fire→start=0, result=0=Aries
        #expect(VargaType.d9.vargaSignIndex(for: 0.0) == 0)
    }

    @Test("Boundary: D9 at exactly 30° (Taurus 0°)")
    func d9At30() {
        // Taurus 0°: compartment=0, earth→start=9, result=9=Capricorn
        #expect(VargaType.d9.vargaSignIndex(for: 30.0) == 9)
    }

    @Test("Boundary: D2 at exactly 15° in odd sign")
    func d2At15OddSign() {
        // Aries 15°: odd sign, deg >= 15 → Cancer(3)
        #expect(VargaType.d2.vargaSignIndex(for: 15.0) == 3)
    }

    @Test("Boundary: D2 just before 15° in odd sign")
    func d2JustBefore15OddSign() {
        // Aries 14.999°: odd sign, deg < 15 → Leo(4)
        #expect(VargaType.d2.vargaSignIndex(for: 14.999) == 4)
    }

    @Test("Boundary: D3 at exactly 10° compartment transition")
    func d3At10Degrees() {
        // Aries 10°: compartment = 1 → 5th from Aries: (0+4)%12 = 4 = Leo
        #expect(VargaType.d3.vargaSignIndex(for: 10.0) == 4)
    }

    @Test("Boundary: D30 at exact boundary 5° in odd sign")
    func d30AtBoundary5OddSign() {
        // Aries 5°: odd sign, degInSign=5 which is NOT < 5, so falls to next bucket
        // Saturn rules 5-10 → Aquarius(10)
        #expect(VargaType.d30.vargaSignIndex(for: 5.0) == 10)
    }

    // MARK: - VargaType metadata tests

    @Test("VargaType has correct count and names")
    func vargaTypeMetadata() {
        #expect(VargaType.allCases.count == 16)
        #expect(VargaType.d1.name == "Rasi")
        #expect(VargaType.d9.name == "Navamsa")
        #expect(VargaType.d9.shortName == "D9")
        #expect(VargaType.d60.shortName == "D60")
    }

    @Test("VargaChart.planetsIn returns correct planets")
    func vargaChartPlanetsIn() async throws {
        let birthData = BirthData.from(
            name: "J2000 Epoch",
            year: 2000, month: 1, day: 1,
            hour: 12, minute: 0, second: 0,
            timeZoneHours: 0.0,
            latitude: 0.0,
            longitude: 0.0
        )

        let calc = ChartCalculator(ephemeris: await eph())
        let chart = await calc.computeChart(for: birthData)
        let vargaCalc = VargaCalculator()
        let d1 = vargaCalc.computeVarga(.d1, from: chart)

        // Every planet returned by planetsIn should actually be in that sign
        for sign in Sign.allCases {
            let planets = d1.planetsIn(sign: sign)
            for planet in planets {
                #expect(d1.sign(of: planet) == sign)
            }
        }
    }
}
