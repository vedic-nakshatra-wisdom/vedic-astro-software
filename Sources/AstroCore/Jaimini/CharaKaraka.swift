import Foundation

/// The Jaimini Chara Karakas (movable significators).
public enum CharaKaraka: String, Codable, Sendable, CaseIterable, CodingKeyRepresentable {
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

        // MARK: - Codable

        private enum CodingKeys: String, CodingKey {
            case planet, degreeInSign, karaka
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(planet, forKey: .planet)
            try container.encode(degreeInSign, forKey: .degreeInSign)
            try container.encode(karaka, forKey: .karaka)
        }
    }

    /// Get the karaka for a planet
    public func karaka(of planet: Planet) -> CharaKaraka? {
        karakas[planet]
    }

    /// Get the planet holding a karaka
    public func planet(for karaka: CharaKaraka) -> Planet? {
        planets[karaka]
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case karakas, planets, isEightKaraka, ranking
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        init(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // Encode karakas in standard planet order
        var karakasContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .karakas)
        let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]
        for planet in planetOrder {
            if let karaka = karakas[planet] {
                try karakasContainer.encode(karaka, forKey: DynamicKey(stringValue: planet.rawValue))
            }
        }

        // Encode planets in karaka order
        var planetsContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .planets)
        let karakaOrder: [CharaKaraka] = [
            .atmakaraka, .amatyakaraka, .bhratrikaraka, .matrikaraka,
            .pitrikaraka, .putrakaraka, .gnatikaraka, .darakaraka
        ]
        for karaka in karakaOrder {
            if let planet = planets[karaka] {
                try planetsContainer.encode(planet, forKey: DynamicKey(stringValue: karaka.rawValue))
            }
        }

        try container.encode(isEightKaraka, forKey: .isEightKaraka)
        try container.encode(ranking, forKey: .ranking)
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
