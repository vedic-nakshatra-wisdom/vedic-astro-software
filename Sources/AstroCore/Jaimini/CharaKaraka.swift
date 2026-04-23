import Foundation

/// The Jaimini Chara Karakas (movable significators).
public enum CharaKaraka: String, Codable, Sendable, CaseIterable {
    case atmakaraka = "Atmakaraka"           // AK - Self/Soul
    case amatyakaraka = "Amatyakaraka"       // AmK - Minister/Career
    case bhratrikaraka = "Bhratrikaraka"     // BK - Siblings
    case matrikaraka = "Matrikaraka"         // MK - Mother
    case pitrikaraka = "Pitrikaraka"         // PiK - Father (8-karaka only)
    case putrakaraka = "Putrakaraka"         // PK - Children
    case gnatikaraka = "Gnatikaraka"         // GK - Rivals/Relatives
    case darakaraka = "Darakaraka"           // DK - Spouse

    public var abbreviation: String {
        switch self {
        case .atmakaraka: return "AK"
        case .amatyakaraka: return "AmK"
        case .bhratrikaraka: return "BK"
        case .matrikaraka: return "MK"
        case .pitrikaraka: return "PiK"
        case .putrakaraka: return "PK"
        case .gnatikaraka: return "GK"
        case .darakaraka: return "DK"
        }
    }

    /// The 7-karaka order (standard, no Pitrikaraka)
    public static let sevenKarakaOrder: [CharaKaraka] = [
        .atmakaraka, .amatyakaraka, .bhratrikaraka, .matrikaraka,
        .putrakaraka, .gnatikaraka, .darakaraka
    ]

    /// The 8-karaka order (includes Pitrikaraka, which the project defaults to)
    public static let eightKarakaOrder: [CharaKaraka] = [
        .atmakaraka, .amatyakaraka, .bhratrikaraka, .matrikaraka,
        .pitrikaraka, .putrakaraka, .gnatikaraka, .darakaraka
    ]
}

/// Result of Chara Karaka calculation.
public struct CharaKarakaResult: Codable, Sendable {
    /// Planet-to-karaka mapping
    public let karakas: [Planet: CharaKaraka]
    /// Karaka-to-planet mapping (reverse lookup)
    public let planets: [CharaKaraka: Planet]
    /// Whether this uses the 8-karaka system (includes Rahu)
    public let isEightKaraka: Bool
    /// Sorted list: (planet, degreeInSign, karaka) from highest to lowest
    public let ranking: [KarakaRanking]

    public struct KarakaRanking: Codable, Sendable {
        public let planet: Planet
        public let degreeInSign: Double
        public let karaka: CharaKaraka
    }

    /// Get the karaka for a planet
    public func karaka(of planet: Planet) -> CharaKaraka? {
        karakas[planet]
    }

    /// Get the planet holding a karaka
    public func planet(for karaka: CharaKaraka) -> Planet? {
        planets[karaka]
    }

    /// Print summary
    public func printSummary() {
        let system = isEightKaraka ? "8-Karaka" : "7-Karaka"
        print("Jaimini Chara Karakas (\(system) System)")
        print(String(repeating: "-", count: 45))
        for entry in ranking {
            let deg = String(format: "%6.2f", entry.degreeInSign)
            print("  \(entry.karaka.abbreviation.padding(toLength: 4, withPad: " ", startingAt: 0))"
                + " \(entry.karaka.rawValue.padding(toLength: 16, withPad: " ", startingAt: 0))"
                + " = \(entry.planet.rawValue.padding(toLength: 8, withPad: " ", startingAt: 0))"
                + " (\(deg)°)")
        }
    }
}
