import Foundation

/// Shadbala (six-fold strength) result for a single planet, in virupas (1/60th of a rupa).
public struct PlanetShadBala: Codable, Sendable {
    public let planet: Planet

    // MARK: - 1. Sthana Bala (Positional Strength)
    public let uchchaBala: Double
    public let saptavargajaBala: Double
    public let ojhayugmarasiBala: Double
    public let kendradiBala: Double
    public let drekkanaBala: Double

    public var sthanaBala: Double {
        uchchaBala + saptavargajaBala + ojhayugmarasiBala + kendradiBala + drekkanaBala
    }

    // MARK: - 2. Dig Bala (Directional Strength)
    public let digBala: Double

    // MARK: - 3. Kala Bala (Temporal Strength)
    // NOTE: Naisargika Bala is NOT part of Kala Bala per BPHS — it's a separate 6th component.
    public let pakshaBala: Double
    public let natonnathaBala: Double
    public let tribhagaBala: Double
    public let abdaBala: Double
    public let masaBala: Double
    public let varaBala: Double
    public let horaBala: Double
    public let ayanaBala: Double

    public var kalaBala: Double {
        pakshaBala + natonnathaBala + tribhagaBala
        + abdaBala + masaBala + varaBala + horaBala + ayanaBala
    }

    // MARK: - 4. Cheshta Bala (Motional Strength)
    // Sun's Cheshta = Ayana Bala, Moon's Cheshta = Paksha Bala (reused values)
    public let cheshtaBala: Double

    // MARK: - 5. Naisargika Bala (Natural Strength) — separate 6th component
    public let naisargikaBala: Double

    // MARK: - 6. Drik Bala (Aspectual Strength)
    public let drikBala: Double

    // MARK: - Totals

    /// Total = Sthana + Dig + Kala + Cheshta + Naisargika + Drik (six-fold)
    public var totalVirupas: Double {
        sthanaBala + digBala + kalaBala + cheshtaBala + naisargikaBala + drikBala
    }

    public var totalRupas: Double {
        totalVirupas / 60.0
    }

    // MARK: - Ishta / Kashta Phala

    public var ishtaPhala: Double {
        sqrt(max(0, uchchaBala) * max(0, cheshtaBala))
    }

    public var kashtaPhala: Double {
        sqrt(max(0, 60.0 - uchchaBala) * max(0, 60.0 - cheshtaBala))
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case planet, uchchaBala, saptavargajaBala, ojhayugmarasiBala
        case kendradiBala, drekkanaBala, digBala, pakshaBala
        case natonnathaBala, tribhagaBala, abdaBala, masaBala, varaBala, horaBala
        case ayanaBala, cheshtaBala, naisargikaBala, drikBala
    }
}

/// Complete Shadbala results for all planets.
public struct ShadBalaResult: Codable, Sendable {
    public let planetBala: [Planet: PlanetShadBala]

    /// Minimum required rupas for each planet (BPHS standard)
    public static let minimumRupas: [Planet: Double] = [
        .sun: 6.5, .moon: 6.0, .mars: 5.0,
        .mercury: 7.0, .jupiter: 6.5, .venus: 5.5, .saturn: 5.0
    ]

    public func meetsMinimum(_ planet: Planet) -> Bool? {
        guard let bala = planetBala[planet],
              let min = Self.minimumRupas[planet] else { return nil }
        return bala.totalRupas >= min
    }

    public var strongest: Planet? {
        planetBala.max(by: { $0.value.totalVirupas < $1.value.totalVirupas })?.key
    }

    public var weakest: Planet? {
        planetBala.min(by: { $0.value.totalVirupas < $1.value.totalVirupas })?.key
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case planetBala
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        init(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var balaContainer = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .planetBala)
        let order: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]
        for planet in order {
            if let bala = planetBala[planet] {
                try balaContainer.encode(bala, forKey: DynamicKey(stringValue: planet.rawValue))
            }
        }
    }
}
