/// Swiss Ephemeris C Bridging Spike Test
/// Verifies the entire pipeline: C compilation → Swift import → ephemeris calculation
///
/// Run with: swift run SpikeTest [path_to_ephemeris_directory]

import Foundation
import AstroCore
import CSwissEph

// MARK: - Test Runner

var passed = 0
var failed = 0

func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
    if condition {
        passed += 1
        print("  PASS: \(message)")
    } else {
        failed += 1
        print("  FAIL: \(message) [\(file):\(line)]")
    }
}

// MARK: - Main

@main
struct SpikeTest {
    static func main() async {
        print("=" * 60)
        print("VedicAstro v0.0 — Swiss Ephemeris C Bridging Spike Test")
        print("=" * 60)

        // Resolve ephemeris path
        let ephePath: String?
        if CommandLine.arguments.count > 1 {
            ephePath = CommandLine.arguments[1]
        } else {
            // Try common locations
            let candidates = [
                FileManager.default.currentDirectoryPath + "/Resources/Ephemeris",
                FileManager.default.currentDirectoryPath + "/../Resources/Ephemeris",
            ]
            ephePath = candidates.first { FileManager.default.fileExists(atPath: $0 + "/sepl_18.se1") }
        }

        if let path = ephePath {
            print("\nEphemeris path: \(path)")
        } else {
            print("\nWARNING: No ephemeris files found. Using Moshier mode (~1 arc-second accuracy).")
        }

        let eph = EphemerisActor()
        await eph.initialize(ephemerisPath: ephePath)
        await eph.setSiderealMode(SE_SIDM_LAHIRI)

        // --- Test 1: Julian Day ---
        print("\n--- Test 1: Julian Day Computation ---")
        let jd = await eph.julianDay(year: 2000, month: 1, day: 1, hour: 12.0)
        print("  JD for 2000-01-01 12:00 UT = \(jd)")
        assert(abs(jd - 2451545.0) < 0.0001, "J2000.0 epoch = 2451545.0")

        // --- Test 2: Ayanamsa ---
        print("\n--- Test 2: Lahiri Ayanamsa ---")
        let ayanamsa = await eph.ayanamsaUT(at: jd)
        print("  Lahiri ayanamsa on 2000-01-01: \(ayanamsa)°")
        print("  In DMS: \(degreesToDMS(ayanamsa))")
        assert(ayanamsa > 23.8 && ayanamsa < 23.9, "Ayanamsa ≈ 23°51' (23.8°-23.9°)")

        // --- Test 3: Sun Position ---
        print("\n--- Test 3: Sun Sidereal Position ---")
        let sun = await eph.calcUT(body: SE_SUN, at: jd)
        assert(sun != nil, "Sun position computable")
        if let sun = sun {
            print("  Longitude: \(sun.longitude)° (\(longitudeToSign(sun.longitude)))")
            print("  Speed: \(sun.speedLon)°/day")
            assert(sun.longitude > 250 && sun.longitude < 265, "Sun in sidereal Sagittarius (~256°)")
            assert(sun.speedLon > 0, "Sun not retrograde")
        }

        // --- Test 4: Moon Position ---
        print("\n--- Test 4: Moon Sidereal Position ---")
        let moon = await eph.calcUT(body: SE_MOON, at: jd)
        assert(moon != nil, "Moon position computable")
        if let moon = moon {
            print("  Longitude: \(moon.longitude)° (\(longitudeToSign(moon.longitude)))")
            print("  Speed: \(moon.speedLon)°/day")
            assert(moon.longitude >= 0 && moon.longitude < 360, "Moon longitude valid")
            assert(moon.speedLon > 10 && moon.speedLon < 16, "Moon speed 10-16°/day")
        }

        // --- Test 5: All 9 Vedic Planets ---
        print("\n--- Test 5: All 9 Vedic Planets ---")
        let bodies: [(String, Int32)] = [
            ("Sun", SE_SUN), ("Moon", SE_MOON), ("Mars", SE_MARS),
            ("Mercury", SE_MERCURY), ("Jupiter", SE_JUPITER),
            ("Venus", SE_VENUS), ("Saturn", SE_SATURN),
            ("Rahu", SE_TRUE_NODE),
        ]

        for (name, body) in bodies {
            let pos = await eph.calcUT(body: body, at: jd)
            assert(pos != nil, "\(name) computes successfully")
            if let pos = pos {
                let signStr = longitudeToSign(pos.longitude)
                let retroStr = pos.speedLon < 0 ? " [R]" : ""
                print("  \(name.padding(toLength: 9, withPad: " ", startingAt: 0)): \(String(format: "%7.3f", pos.longitude))° \(signStr)\(retroStr)")
            }
        }

        // Ketu = Rahu + 180°
        if let rahu = await eph.calcUT(body: SE_TRUE_NODE, at: jd) {
            let ketuLon = (rahu.longitude + 180.0).truncatingRemainder(dividingBy: 360.0)
            print("  Ketu     : \(String(format: "%7.3f", ketuLon))° \(longitudeToSign(ketuLon)) [R]")
        }

        // --- Test 6: Nakshatra Check ---
        print("\n--- Test 6: Nakshatra Derivation (Pure Math) ---")
        if let moon = moon {
            let nakshatraSpan = 360.0 / 27.0 // 13.333°
            let nakIndex = Int(moon.longitude / nakshatraSpan)
            let padaSpan = nakshatraSpan / 4.0
            let posInNak = moon.longitude - Double(nakIndex) * nakshatraSpan
            let pada = Int(posInNak / padaSpan) + 1
            let nakshatras = [
                "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
                "Punarvasu", "Pushya", "Ashlesha", "Magha", "P.Phalguni", "U.Phalguni",
                "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha",
                "Mula", "P.Ashadha", "U.Ashadha", "Shravana", "Dhanishtha",
                "Shatabhisha", "P.Bhadrapada", "U.Bhadrapada", "Revati"
            ]
            print("  Moon nakshatra: \(nakshatras[nakIndex]) (Pada \(pada))")
            assert(nakIndex >= 0 && nakIndex < 27, "Nakshatra index valid")
            assert(pada >= 1 && pada <= 4, "Pada valid (1-4)")
        }

        // --- Test 7: Navamsa Check (Pure Math) ---
        print("\n--- Test 7: Navamsa D9 (Pure Math) ---")
        if let sun = sun {
            let signIndex = Int(sun.longitude / 30.0)
            let degInSign = sun.longitude - Double(signIndex) * 30.0
            let part = Int(degInSign * 9.0 / 30.0)
            let d9Sign = (signIndex * 9 + part) % 12
            let signs = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                         "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
            print("  Sun D1: \(signs[signIndex]) → D9: \(signs[d9Sign])")
            assert(d9Sign >= 0 && d9Sign < 12, "D9 sign valid")
        }

        // --- Summary ---
        await eph.close()

        print("\n" + "=" * 60)
        print("Results: \(passed) passed, \(failed) failed, \(passed + failed) total")
        if failed == 0 {
            print("v0.0 SPIKE: ALL TESTS PASSED")
        } else {
            print("v0.0 SPIKE: \(failed) TEST(S) FAILED")
        }
        print("=" * 60)

        if failed > 0 {
            Foundation.exit(1)
        }
    }
}

// MARK: - Helpers

func degreesToDMS(_ degrees: Double) -> String {
    let d = Int(degrees)
    let mFull = (degrees - Double(d)) * 60.0
    let m = Int(mFull)
    let s = (mFull - Double(m)) * 60.0
    return "\(d)°\(m)'\(String(format: "%.1f", s))\""
}

func longitudeToSign(_ longitude: Double) -> String {
    let signs = ["Ari", "Tau", "Gem", "Can", "Leo", "Vir",
                 "Lib", "Sco", "Sag", "Cap", "Aqu", "Pis"]
    let signIndex = Int(longitude / 30.0) % 12
    let degInSign = longitude - Double(signIndex) * 30.0
    return "\(signs[signIndex]) \(String(format: "%.1f", degInSign))°"
}

extension String {
    static func * (lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}
