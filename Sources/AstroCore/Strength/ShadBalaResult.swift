import Foundation

/// Shadbala (six-fold strength) result for a single planet, in virupas (1/60th of a rupa).
public struct PlanetShadBala: Codable, Sendable {
    public let planet: Planet

    // MARK: - 1. Sthana Bala (Positional Strength)
    /// Exaltation strength (0–60 virupas)
    public let uchchaBala: Double
    /// Saptavargaja Bala — dignity in 7 vargas (TODO: needs friendship tables)
    public let saptavargajaBala: Double
    /// Odd/even sign + navamsa strength (0–30 virupas)
    public let ojhayugmarasiBala: Double
    /// Kendra/Panapara/Apoklima strength (15, 30, or 60 virupas)
    public let kendradiBala: Double
    /// Decanate strength (0 or 15 virupas)
    public let drekkanaBala: Double

    /// Total Sthana Bala
    public var sthanaBala: Double {
        uchchaBala + saptavargajaBala + ojhayugmarasiBala + kendradiBala + drekkanaBala
    }

    // MARK: - 2. Dig Bala (Directional Strength)
    /// Directional strength (0–60 virupas)
    public let digBala: Double

    // MARK: - 3. Kala Bala (Temporal Strength — partial)
    /// Natural strength — fixed per planet (8.57–60 virupas)
    public let naisargikaBala: Double
    /// Paksha Bala — lunar phase strength (0–60 virupas)
    public let pakshaBala: Double
    // TODO: Natonnata, Tribhaga, Abda/Masa/Vara/Hora (need sunrise/sunset)

    /// Total Kala Bala (computed components only)
    public var kalaBala: Double {
        naisargikaBala + pakshaBala
    }

    // MARK: - 4–6. Uncomputed (need additional data)
    // Cheshta Bala (motional), Ayana Bala (declination), Drig Bala (aspectual)
    // Marked 0 until sunrise/sunset + tropical longitudes available

    /// Total Shadbala (sum of all computed components)
    public var totalVirupas: Double {
        sthanaBala + digBala + kalaBala
    }

    /// Total in rupas (1 rupa = 60 virupas)
    public var totalRupas: Double {
        totalVirupas / 60.0
    }
}

/// Complete Shadbala results for all planets.
public struct ShadBalaResult: Codable, Sendable {
    /// Per-planet Shadbala breakdown
    public let planetBala: [Planet: PlanetShadBala]

    /// Minimum required rupas for each planet (BPHS standard)
    public static let minimumRupas: [Planet: Double] = [
        .sun: 6.5, .moon: 6.0, .mars: 5.0,
        .mercury: 7.0, .jupiter: 6.5, .venus: 5.5, .saturn: 5.0
    ]

    /// Check if a planet meets its minimum Shadbala requirement
    public func meetsMinimum(_ planet: Planet) -> Bool? {
        guard let bala = planetBala[planet],
              let min = Self.minimumRupas[planet] else { return nil }
        return bala.totalRupas >= min
    }

    /// Strongest planet by total virupas
    public var strongest: Planet? {
        planetBala.max(by: { $0.value.totalVirupas < $1.value.totalVirupas })?.key
    }

    /// Weakest planet by total virupas
    public var weakest: Planet? {
        planetBala.min(by: { $0.value.totalVirupas < $1.value.totalVirupas })?.key
    }
}
