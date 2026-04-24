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

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case atmakaraka, karakamsaSign, planetsInKarakamsa, houseFromLagna
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(atmakaraka, forKey: .atmakaraka)
        try container.encode(karakamsaSign, forKey: .karakamsaSign)
        try container.encode(planetsInKarakamsa, forKey: .planetsInKarakamsa)
        try container.encodeIfPresent(houseFromLagna, forKey: .houseFromLagna)
    }
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

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case atmakaraka, karakamsa, akNavamsaSign, twelfthSign
        case planetsInTwelfth, significator, deity
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(atmakaraka, forKey: .atmakaraka)
        try container.encode(karakamsa, forKey: .karakamsa)
        try container.encode(akNavamsaSign, forKey: .akNavamsaSign)
        try container.encode(twelfthSign, forKey: .twelfthSign)
        try container.encode(planetsInTwelfth, forKey: .planetsInTwelfth)
        try container.encode(significator, forKey: .significator)
        try container.encode(deity, forKey: .deity)
    }

    /// Vedic deities associated with planetary significators.
    /// Each planet maps to a primary deity with alternates from various Jaimini traditions.
    public struct Deity: Codable, Sendable, Equatable {
        /// Primary deity name
        public let primary: String
        /// Alternative deities from different traditions
        public let alternates: [String]
        /// Devotional theme this planet represents
        public let theme: String

        // MARK: - Codable

        private enum CodingKeys: String, CodingKey {
            case primary, alternates, theme
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(primary, forKey: .primary)
            try container.encode(alternates, forKey: .alternates)
            try container.encode(theme, forKey: .theme)
        }

        /// Map a planet to its deity per Jaimini tradition
        public static func from(planet: Planet) -> Deity {
            switch planet {
            case .sun:
                return Deity(
                    primary: "Lord Rama",
                    alternates: ["Lord Shiva", "Surya Narayana"],
                    theme: "Dharma, soul, and royal devotion"
                )
            case .moon:
                return Deity(
                    primary: "Lord Krishna",
                    alternates: ["Goddess Parvati", "Goddess Gauri"],
                    theme: "Devotion through love, emotion, and the divine mother"
                )
            case .mars:
                return Deity(
                    primary: "Lord Hanuman",
                    alternates: ["Lord Subramanya/Kartikeya/Murugan", "Lord Narasimha"],
                    theme: "Courage, protection, and warrior devotion"
                )
            case .mercury:
                return Deity(
                    primary: "Lord Vishnu (Vitthala)",
                    alternates: ["Lord Krishna (cowherd form)"],
                    theme: "Intellect, communication, and playful devotion"
                )
            case .jupiter:
                return Deity(
                    primary: "Lord Vishnu",
                    alternates: ["Lord Vamana", "Sri Hari", "Lord Dattatreya"],
                    theme: "Wisdom, dharma, and guru-bhakti"
                )
            case .venus:
                return Deity(
                    primary: "Goddess Lakshmi",
                    alternates: ["Lord Parashurama", "Goddess Gauri"],
                    theme: "Devotion through beauty, love, and abundance"
                )
            case .saturn:
                return Deity(
                    primary: "Lord Shiva (Bhairava)",
                    alternates: ["Lord Hanuman", "Lord Kurma"],
                    theme: "Discipline, austerity, and shadow work"
                )
            case .rahu:
                return Deity(
                    primary: "Goddess Durga",
                    alternates: ["Lord Varaha", "Goddess Chamunda"],
                    theme: "Unconventional paths, tantric devotion, and breaking illusion"
                )
            case .ketu:
                return Deity(
                    primary: "Lord Ganesha",
                    alternates: ["Lord Matsya", "Lord Shiva (Dakshinamurti)"],
                    theme: "Moksha, spiritual liberation, and detachment"
                )
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
