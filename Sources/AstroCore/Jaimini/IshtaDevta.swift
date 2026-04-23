import Foundation

/// Ishta Devta (chosen deity) calculation per Jaimini system.
///
/// Method: Find the Atmakaraka's sign in Navamsa (D9) = Karakamsa.
/// Compute the 12th sign from Karakamsa. Check the D1 (rasi) chart
/// for planets occupying that 12th sign. If a planet is there, it
/// indicates the deity. If empty, the lord of that sign indicates the deity.
/// Karakamsa — the Navamsa sign of the Atmakaraka.
/// Foundation for Ishta Devta, Swamsa analysis, and Jaimini predictions.
public struct KarakamsaResult: Codable, Sendable {
    /// The Atmakaraka planet
    public let atmakaraka: Planet
    /// Karakamsa sign (AK's Navamsa sign)
    public let karakamsaSign: Sign
    /// Planets in the Karakamsa sign (in D9)
    public let planetsInKarakamsa: [Planet]
    /// House number of Karakamsa from D1 Lagna (Whole Sign)
    public let houseFromLagna: Int?
}

public struct IshtaDevtaResult: Codable, Sendable {
    /// The Atmakaraka planet
    public let atmakaraka: Planet
    /// Karakamsa (AK's Navamsa sign) — core Jaimini reference
    public let karakamsa: KarakamsaResult
    /// AK's sign in Navamsa (same as karakamsa.karakamsaSign)
    public let akNavamsaSign: Sign
    /// The 12th sign from AK's Navamsa sign
    public let twelfthSign: Sign
    /// Planet(s) occupying the 12th sign (may be empty)
    public let planetsInTwelfth: [Planet]
    /// The significator planet: first planet in 12th, or lord of 12th if empty
    public let significator: Planet
    /// The indicated deity
    public let deity: Deity

    /// Vedic deities associated with planetary significators
    public enum Deity: String, Codable, Sendable {
        case shiva = "Lord Shiva"
        case parvati = "Goddess Parvati/Durga"
        case skanda = "Lord Skanda/Kartikeya"
        case vishnu = "Lord Vishnu"
        case lakshmi = "Goddess Lakshmi"
        case ganesha = "Lord Ganesha"
        case narasimha = "Lord Narasimha"
        case rama = "Lord Rama"
        case krishna = "Lord Krishna"
        case hanuman = "Lord Hanuman"
        case surya = "Lord Surya"
        case chamundi = "Goddess Chamundi"

        /// Map a planet to its primary deity per Jaimini tradition
        public static func from(planet: Planet) -> Deity {
            switch planet {
            case .sun:     return .shiva
            case .moon:    return .parvati
            case .mars:    return .skanda
            case .mercury: return .vishnu
            case .jupiter: return .narasimha
            case .venus:   return .lakshmi
            case .saturn:  return .hanuman
            case .rahu:    return .chamundi
            case .ketu:    return .ganesha
            }
        }
    }
}

/// Computes the Ishta Devta from a birth chart and Jaimini karakas.
public struct IshtaDevtaCalculator: Sendable {

    public init() {}

    /// Compute Ishta Devta. Requires karakas (for AK) and birth chart with ascendant.
    public func compute(
        from chart: BirthChart,
        karakas: CharaKarakaResult
    ) -> IshtaDevtaResult? {
        guard let akPlanet = karakas.planet(for: .atmakaraka),
              chart.position(of: akPlanet) != nil,
              chart.ascendant != nil else { return nil }

        // Build Navamsa placements for all planets
        var navamsaPlacements: [Planet: Int] = [:]
        for planet in Planet.allCases {
            guard let pos = chart.position(of: planet) else { continue }
            navamsaPlacements[planet] = VargaType.d9.vargaSignIndex(for: pos.longitude)
        }

        // AK's Navamsa sign = Karakamsa
        let navamsaSignIndex = navamsaPlacements[akPlanet]!
        let akNavamsaSign = Sign(rawValue: navamsaSignIndex)!

        // Planets in Karakamsa (D9)
        var planetsInKarakamsa: [Planet] = []
        for planet in Planet.allCases {
            if let idx = navamsaPlacements[planet], idx == navamsaSignIndex {
                planetsInKarakamsa.append(planet)
            }
        }

        // Karakamsa house from D1 Lagna
        let karakamsaHouse: Int?
        if let lagnaIndex = chart.ascendant?.signIndex {
            karakamsaHouse = ((navamsaSignIndex - lagnaIndex + 12) % 12) + 1
        } else {
            karakamsaHouse = nil
        }

        let karakamsa = KarakamsaResult(
            atmakaraka: akPlanet,
            karakamsaSign: akNavamsaSign,
            planetsInKarakamsa: planetsInKarakamsa,
            houseFromLagna: karakamsaHouse
        )

        // 12th from Karakamsa = sign before it
        let twelfthIndex = (navamsaSignIndex + 11) % 12
        let twelfthSign = Sign(rawValue: twelfthIndex)!

        // Find planets in the 12th sign in the D1 (rasi) chart
        var planetsInTwelfth: [Planet] = []
        for planet in Planet.allCases {
            guard let pos = chart.position(of: planet) else { continue }
            if pos.signIndex == twelfthIndex {
                planetsInTwelfth.append(planet)
            }
        }

        // Significator: first planet in 12th, or lord of 12th sign
        let significator: Planet
        if let firstPlanet = planetsInTwelfth.first {
            significator = firstPlanet
        } else {
            significator = twelfthSign.lord
        }

        return IshtaDevtaResult(
            atmakaraka: akPlanet,
            karakamsa: karakamsa,
            akNavamsaSign: akNavamsaSign,
            twelfthSign: twelfthSign,
            planetsInTwelfth: planetsInTwelfth,
            significator: significator,
            deity: IshtaDevtaResult.Deity.from(planet: significator)
        )
    }
}
