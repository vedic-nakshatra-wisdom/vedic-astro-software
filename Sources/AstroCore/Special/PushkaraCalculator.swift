import Foundation

/// Pushkara analysis result for a single planet.
public struct PushkaraInfo: Codable, Sendable {
    public let planet: Planet
    /// Whether the planet is in a Pushkara Navamsa (D9 sign ruled by Jupiter or Venus)
    public let isInPushkaraNavamsa: Bool
    /// The navamsa sign this planet occupies
    public let navamsaSign: Sign
    /// Whether the planet is at/near a Pushkara Bhaga degree (within 1° orb)
    public let isAtPushkaraBhaga: Bool
    /// The exact Pushkara Bhaga degree for this planet's sign
    public let pushkaraBhagaDegree: Double
    /// The planet's actual degree in sign
    public let degreeInSign: Double
    /// Distance from Pushkara Bhaga (in degrees)
    public let orbFromPushkaraBhaga: Double

    enum CodingKeys: String, CodingKey {
        case planet, isInPushkaraNavamsa, navamsaSign, isAtPushkaraBhaga
        case pushkaraBhagaDegree, degreeInSign, orbFromPushkaraBhaga
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(planet, forKey: .planet)
        try container.encode(isInPushkaraNavamsa, forKey: .isInPushkaraNavamsa)
        try container.encode(navamsaSign, forKey: .navamsaSign)
        try container.encode(isAtPushkaraBhaga, forKey: .isAtPushkaraBhaga)
        try container.encode(pushkaraBhagaDegree, forKey: .pushkaraBhagaDegree)
        try container.encode(degreeInSign, forKey: .degreeInSign)
        try container.encode(orbFromPushkaraBhaga, forKey: .orbFromPushkaraBhaga)
    }
}

/// Complete Pushkara analysis for a chart.
public struct PushkaraResult: Codable, Sendable {
    public let planets: [PushkaraInfo]

    /// Planets in Pushkara Navamsa
    public var pushkaraNavamsaPlanets: [PushkaraInfo] {
        planets.filter { $0.isInPushkaraNavamsa }
    }

    /// Planets at Pushkara Bhaga
    public var pushkaraBhagaPlanets: [PushkaraInfo] {
        planets.filter { $0.isAtPushkaraBhaga }
    }

    enum CodingKeys: String, CodingKey {
        case planets
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(planets, forKey: .planets)
    }
}

/// Computes Pushkara Navamsa and Pushkara Bhaga for all planets.
public struct PushkaraCalculator: Sendable {

    public init() {}

    /// Pushkara Bhaga degrees per sign (index = Sign.rawValue)
    private static let pushkaraBhagaDegrees: [Double] = [
        21, // Aries
        14, // Taurus
        18, // Gemini
         8, // Cancer
        19, // Leo
         9, // Virgo
        24, // Libra
        11, // Scorpio
        23, // Sagittarius
        14, // Capricorn
        19, // Aquarius
         9  // Pisces
    ]

    /// Signs ruled by Jupiter or Venus (the Pushkara Navamsa signs)
    /// Taurus (1), Libra (6), Sagittarius (8), Pisces (11)
    private static let pushkaraNavamsaSigns: Set<Int> = [1, 6, 8, 11]

    /// Compute Pushkara analysis for all planets in the chart.
    public func compute(from chart: BirthChart) -> PushkaraResult {
        let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]

        let infos: [PushkaraInfo] = planetOrder.compactMap { planet in
            guard let pos = chart.position(of: planet) else { return nil }

            let signIndex = pos.sign.rawValue
            let degInSign = pos.degreeInSign

            // Pushkara Navamsa: check D9 sign
            let navamsaSignIndex = VargaType.d9.vargaSignIndex(for: pos.longitude)
            let navamsaSign = Sign(rawValue: navamsaSignIndex)!
            let isPN = Self.pushkaraNavamsaSigns.contains(navamsaSignIndex)

            // Pushkara Bhaga: check degree proximity
            let pbDegree = Self.pushkaraBhagaDegrees[signIndex]
            let orb = abs(degInSign - pbDegree)
            let isPB = orb <= 1.0

            return PushkaraInfo(
                planet: planet,
                isInPushkaraNavamsa: isPN,
                navamsaSign: navamsaSign,
                isAtPushkaraBhaga: isPB,
                pushkaraBhagaDegree: pbDegree,
                degreeInSign: degInSign,
                orbFromPushkaraBhaga: orb
            )
        }

        return PushkaraResult(planets: infos)
    }
}
