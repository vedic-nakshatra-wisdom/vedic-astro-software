import Foundation

/// The 9 Vedic grahas (celestial bodies) used in Jyotish.
/// Rahu and Ketu are lunar nodes, not physical planets.
public enum Planet: String, Codable, Sendable, CaseIterable, Hashable {
    case sun = "Sun"
    case moon = "Moon"
    case mars = "Mars"
    case mercury = "Mercury"
    case jupiter = "Jupiter"
    case venus = "Venus"
    case saturn = "Saturn"
    case rahu = "Rahu"
    case ketu = "Ketu"

    /// Swiss Ephemeris body constant. Ketu is derived (Rahu + 180°), not from SE.
    public var seBody: Int32? {
        switch self {
        case .sun:     return 0   // SE_SUN
        case .moon:    return 1   // SE_MOON
        case .mercury: return 2   // SE_MERCURY
        case .venus:   return 3   // SE_VENUS
        case .mars:    return 4   // SE_MARS
        case .jupiter: return 5   // SE_JUPITER
        case .saturn:  return 6   // SE_SATURN
        case .rahu:    return 11  // SE_TRUE_NODE (default; SE_MEAN_NODE = 10)
        case .ketu:    return nil // Derived from Rahu
        }
    }

    /// Natural benefic or malefic classification
    public var isNaturalBenefic: Bool {
        switch self {
        case .jupiter, .venus: return true
        case .moon: return true // Waxing moon; context-dependent
        case .mercury: return true // When unafflicted
        default: return false
        }
    }

    /// Planets that own signs (excludes Rahu/Ketu in Parashari)
    public static let signLords: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]

    /// Planets used in Ashtakavarga (7 planets, no Rahu/Ketu)
    public static let ashtakavargaPlanets: [Planet] = signLords

    /// Vimshottari Maha Dasha period in years (total cycle = 120 years)
    public var vimshottariYears: Double {
        switch self {
        case .ketu:    return 7
        case .venus:   return 20
        case .sun:     return 6
        case .moon:    return 10
        case .mars:    return 7
        case .rahu:    return 18
        case .jupiter: return 16
        case .saturn:  return 19
        case .mercury: return 17
        }
    }
}
