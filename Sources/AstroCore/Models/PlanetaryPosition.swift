import Foundation

/// Complete position data for a single planet/body.
public struct PlanetaryPosition: Codable, Sendable, Hashable {
    /// Which planet this position is for
    public let planet: Planet
    /// Sidereal longitude in degrees (0-360)
    public let longitude: Double
    /// Ecliptic latitude in degrees
    public let latitude: Double
    /// Speed in longitude (degrees/day). Negative = retrograde.
    public let speedLongitude: Double
    /// Distance from Earth (AU for planets, Earth radii for Moon)
    public let distance: Double

    // MARK: - Derived (pure math from longitude)

    /// Sign index (0-11)
    public var signIndex: Int { Int(longitude / 30.0) % 12 }
    /// Zodiac sign
    public var sign: Sign { Sign(rawValue: signIndex)! }
    /// Degree within sign (0-30)
    public var degreeInSign: Double { longitude - Double(signIndex) * 30.0 }

    /// Nakshatra
    public var nakshatra: Nakshatra { Nakshatra.from(longitude: longitude).nakshatra }
    /// Nakshatra pada (1-4)
    public var nakshatraPada: Int { Nakshatra.from(longitude: longitude).pada }

    /// Whether the planet is retrograde
    public var isRetrograde: Bool { speedLongitude < 0 }

    /// Formatted degree in sign (e.g., "15°23'45\"")
    public var formattedDegree: String {
        let deg = degreeInSign
        let d = Int(deg)
        let mFull = (deg - Double(d)) * 60.0
        let m = Int(mFull)
        let s = Int((mFull - Double(m)) * 60.0)
        return "\(d)°\(String(format: "%02d", m))'\(String(format: "%02d", s))\""
    }

    /// Short display string (e.g., "Sag 16°31'")
    public var shortDescription: String {
        let retro = isRetrograde ? " [R]" : ""
        return "\(sign.shortName) \(formattedDegree)\(retro)"
    }

    /// Create from raw Swiss Ephemeris output
    public static func from(
        planet: Planet,
        longitude: Double,
        latitude: Double,
        distance: Double,
        speedLongitude: Double
    ) -> PlanetaryPosition {
        PlanetaryPosition(
            planet: planet,
            longitude: longitude,
            latitude: latitude,
            speedLongitude: speedLongitude,
            distance: distance
        )
    }
}
