import Testing
@testable import AstroCore
import CSwissEph
import Foundation

@Suite("Swiss Ephemeris C Bridging Spike", .serialized)
struct EphemerisTests {

    private func eph() async -> EphemerisActor {
        await TestEphemeris.initialize()
        await TestEphemeris.shared.setSiderealMode(SE_SIDM_LAHIRI)
        return TestEphemeris.shared
    }

    @Test("Sun position at J2000 epoch")
    func sunPositionJ2000() async throws {
        let eph = await eph()

        let jd = await eph.julianDay(year: 2000, month: 1, day: 1, hour: 12.0)
        #expect(abs(jd - 2451545.0) < 0.0001, "Julian Day for J2000.0 epoch")

        let sun = await eph.calcUT(body: SE_SUN, at: jd)
        #expect(sun != nil, "Sun position should not be nil")
        guard let sun = sun else { return }

        #expect(sun.longitude > 250.0, "Sun sidereal longitude should be > 250°")
        #expect(sun.longitude < 265.0, "Sun sidereal longitude should be < 265°")
        #expect(sun.speedLon > 0, "Sun should have positive speed")

        print("Sun sidereal longitude: \(sun.longitude)°")
        print("Sun speed: \(sun.speedLon)°/day")

        let ayanamsa = await eph.ayanamsaUT(at: jd)
        #expect(ayanamsa > 23.8, "Lahiri ayanamsa should be > 23.8°")
        #expect(ayanamsa < 23.9, "Lahiri ayanamsa should be < 23.9°")
        print("Lahiri ayanamsa: \(ayanamsa)°")
    }

    @Test("Moon position at J2000 epoch")
    func moonPositionJ2000() async throws {
        let eph = await eph()

        let jd = await eph.julianDay(year: 2000, month: 1, day: 1, hour: 12.0)
        let moon = await eph.calcUT(body: SE_MOON, at: jd)
        #expect(moon != nil, "Moon position should not be nil")
        guard let moon = moon else { return }

        #expect(moon.longitude >= 0.0)
        #expect(moon.longitude < 360.0)
        #expect(moon.speedLon > 10.0, "Moon speed too slow")
        #expect(moon.speedLon < 16.0, "Moon speed too fast")

        print("Moon sidereal longitude: \(moon.longitude)°")
        print("Moon speed: \(moon.speedLon)°/day")
    }

    @Test("Rahu (True Node) position")
    func rahuPosition() async throws {
        let eph = await eph()

        let jd = await eph.julianDay(year: 2000, month: 1, day: 1, hour: 12.0)
        let rahu = await eph.calcUT(body: SE_TRUE_NODE, at: jd)
        #expect(rahu != nil, "Rahu position should not be nil")
        guard let rahu = rahu else { return }

        #expect(rahu.longitude >= 0.0)
        #expect(rahu.longitude < 360.0)

        print("Rahu (True Node) sidereal longitude: \(rahu.longitude)°")
        print("Rahu speed: \(rahu.speedLon)°/day")
    }

    @Test("All 9 Vedic planets compute successfully")
    func allPlanets() async throws {
        let eph = await eph()

        let jd = await eph.julianDay(year: 2000, month: 1, day: 1, hour: 12.0)

        let bodies: [(String, Int32)] = [
            ("Sun", SE_SUN), ("Moon", SE_MOON), ("Mercury", SE_MERCURY),
            ("Venus", SE_VENUS), ("Mars", SE_MARS), ("Jupiter", SE_JUPITER),
            ("Saturn", SE_SATURN), ("Rahu", SE_TRUE_NODE),
        ]

        for (name, body) in bodies {
            let pos = await eph.calcUT(body: body, at: jd)
            #expect(pos != nil, "\(name) should compute successfully")
            if let pos = pos {
                #expect(pos.longitude >= 0.0 && pos.longitude < 360.0,
                       "\(name) longitude should be 0-360°")
                print("\(name): \(pos.longitude)°")
            }
        }

        let rahu = await eph.calcUT(body: SE_TRUE_NODE, at: jd)
        if let rahu = rahu {
            let ketuLongitude = (rahu.longitude + 180.0).truncatingRemainder(dividingBy: 360.0)
            #expect(ketuLongitude >= 0.0 && ketuLongitude < 360.0)
            print("Ketu (derived): \(ketuLongitude)°")
        }
    }
}
