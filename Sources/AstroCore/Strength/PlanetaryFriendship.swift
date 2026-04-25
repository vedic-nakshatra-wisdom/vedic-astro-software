import Foundation

/// Natural (Naisargika) friendship between planets per BPHS.
public enum FriendshipLevel: Int, Sendable, Comparable {
    case adhiShatru = -2   // Great Enemy
    case shatru = -1       // Enemy
    case sama = 0          // Neutral
    case mitra = 1         // Friend
    case adhiMitra = 2     // Great Friend

    public static func < (lhs: FriendshipLevel, rhs: FriendshipLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Planetary friendship calculations for Shadbala (Saptavargaja Bala).
public struct PlanetaryFriendship: Sendable {

    // MARK: - Natural (Naisargika) Friendship

    /// Natural friendship table per BPHS.
    /// Returns .mitra, .shatru, or .sama for the natural relationship.
    public static func naturalFriendship(of planet: Planet, with other: Planet) -> FriendshipLevel {
        guard planet != other else { return .sama }
        guard let friends = naturalFriends[planet],
              let enemies = naturalEnemies[planet] else { return .sama }
        if friends.contains(other) { return .mitra }
        if enemies.contains(other) { return .shatru }
        return .sama
    }

    private static let naturalFriends: [Planet: Set<Planet>] = [
        .sun:     [.moon, .mars, .jupiter],
        .moon:    [.sun, .mercury],
        .mars:    [.sun, .moon, .jupiter],
        .mercury: [.sun, .venus],
        .jupiter: [.sun, .moon, .mars],
        .venus:   [.mercury, .saturn],
        .saturn:  [.mercury, .venus],
    ]

    private static let naturalEnemies: [Planet: Set<Planet>] = [
        .sun:     [.venus, .saturn],
        .moon:    [],  // Moon has no natural enemies
        .mars:    [.mercury],
        .mercury: [.moon],
        .jupiter: [.mercury, .venus],
        .venus:   [.sun, .moon],
        .saturn:  [.sun, .moon, .mars],
    ]

    // MARK: - Temporary (Tatkalika) Friendship

    /// Temporary friendship based on relative positions in D1.
    /// Planets in houses 2, 3, 4, 10, 11, 12 from a planet are temporary friends.
    /// Planets in houses 1, 5, 6, 7, 8, 9 are temporary enemies.
    public static func temporaryFriendship(
        of planet: Planet, with other: Planet, chart: BirthChart
    ) -> FriendshipLevel {
        guard planet != other else { return .sama }
        guard let planetSign = chart.position(of: planet)?.signIndex,
              let otherSign = chart.position(of: other)?.signIndex else { return .sama }

        // House distance (sign-based, 1-indexed)
        let distance = ((otherSign - planetSign + 12) % 12) + 1

        // Houses 2,3,4,10,11,12 = friend; 1,5,6,7,8,9 = enemy
        switch distance {
        case 2, 3, 4, 10, 11, 12: return .mitra
        default: return .shatru
        }
    }

    // MARK: - Compound (Panchada) Friendship

    /// Compound friendship = natural + temporary combined.
    public static func compoundFriendship(
        of planet: Planet, with other: Planet, chart: BirthChart
    ) -> FriendshipLevel {
        guard planet != other else { return .sama }
        let natural = naturalFriendship(of: planet, with: other)
        let temporary = temporaryFriendship(of: planet, with: other, chart: chart)

        let combined = natural.rawValue + temporary.rawValue
        switch combined {
        case 2:  return .adhiMitra   // Friend + Friend
        case 1:  return .mitra       // Friend + Neutral or Neutral + Friend
        case 0:  return .sama        // Neutral + Neutral, or Friend + Enemy, or Enemy + Friend
        case -1: return .shatru      // Enemy + Neutral or Neutral + Enemy
        case -2: return .adhiShatru  // Enemy + Enemy
        default: return .sama
        }
    }

    // MARK: - Saptavargaja Scoring

    /// Virupas for a planet's dignity in a varga sign.
    /// Checks: Moolatrikona, own sign, or compound friendship with sign lord.
    public static func saptavargajaPoints(
        planet: Planet,
        inSign sign: Sign,
        chart: BirthChart,
        isMoolatrikona: Bool = false
    ) -> Double {
        // Moolatrikona (only in D1, specific degree ranges)
        if isMoolatrikona { return 45.0 }

        // Own sign
        if sign.lord == planet { return 30.0 }

        // Exaltation sign (treated as own-sign level in some traditions)
        // Not standard for Saptavargaja — use friendship instead

        let lord = sign.lord
        let friendship = compoundFriendship(of: planet, with: lord, chart: chart)

        // BPHS scoring: Pramudita=20, Shanta=15, Dina=10, Duhkhita=4, Khala=2
        switch friendship {
        case .adhiMitra: return 20.0
        case .mitra:     return 15.0
        case .sama:      return 10.0
        case .shatru:    return 4.0
        case .adhiShatru: return 2.0
        }
    }

    // MARK: - Moolatrikona Detection

    /// Moolatrikona signs and degree ranges per BPHS.
    public static func isMoolatrikona(planet: Planet, longitude: Double) -> Bool {
        let sign = Sign.from(longitude: longitude)
        let deg = longitude - Double(sign.rawValue) * 30.0

        switch planet {
        case .sun:     return sign == .leo && deg >= 0 && deg < 20
        case .moon:    return sign == .taurus && deg >= 3 && deg < 30
        case .mars:    return sign == .aries && deg >= 0 && deg < 12
        case .mercury: return sign == .virgo && deg >= 16 && deg < 20
        case .jupiter: return sign == .sagittarius && deg >= 0 && deg < 10
        case .venus:   return sign == .libra && deg >= 0 && deg < 15
        case .saturn:  return sign == .aquarius && deg >= 0 && deg < 20
        default:       return false
        }
    }
}
