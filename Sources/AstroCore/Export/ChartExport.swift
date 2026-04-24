import Foundation

/// Complete chart export bundle — single Codable root for JSON export
/// and input for Markdown formatting.
///
/// Fields are ordered for readability:
/// metadata → birthData → rasiChart → divisionalCharts → dashas →
/// ashtakavarga → shadbala → jaimini → specialPoints
public struct ChartExport: Codable, Sendable {

    // --- Section 1: Metadata ---
    public let metadata: ExportMetadata

    // --- Section 2: Birth Data (input) ---
    public let birthData: BirthDataExport

    // --- Section 3: Rasi Chart (D1) ---
    public let rasiChart: RasiChartExport

    // --- Section 4: Divisional Charts (D1–D60, sorted) ---
    public let divisionalCharts: [VargaExport]

    // --- Section 5: Vimshottari Dasha ---
    public let vimshottariDasha: VimshottariDashaExport?

    // --- Section 6: Ashtakavarga ---
    public let ashtakavarga: AshtakavargaResult?

    // --- Section 7: Shadbala ---
    public let shadbala: ShadBalaResult?

    // --- Section 8: Jaimini System ---
    public let jaimini: JaiminiExport?

    // --- Section 9: Special Points ---
    public let specialPoints: SpecialPointsExport?

    // MARK: - Coding Keys (controls JSON field order)

    enum CodingKeys: String, CodingKey {
        case metadata
        case birthData
        case rasiChart
        case divisionalCharts
        case vimshottariDasha
        case ashtakavarga
        case shadbala
        case jaimini
        case specialPoints
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(birthData, forKey: .birthData)
        try container.encode(rasiChart, forKey: .rasiChart)
        try container.encode(divisionalCharts, forKey: .divisionalCharts)
        try container.encodeIfPresent(vimshottariDasha, forKey: .vimshottariDasha)
        try container.encodeIfPresent(ashtakavarga, forKey: .ashtakavarga)
        try container.encodeIfPresent(shadbala, forKey: .shadbala)
        try container.encodeIfPresent(jaimini, forKey: .jaimini)
        try container.encodeIfPresent(specialPoints, forKey: .specialPoints)
    }
}

// MARK: - Sub-structures

public struct ExportMetadata: Codable, Sendable {
    public let engineVersion: String
    public let exportDate: Date
    public let ayanamsa: String
    public let ayanamsaValue: Double
    public let houseSystem: String
    public let nodeType: String

    enum CodingKeys: String, CodingKey {
        case engineVersion, exportDate, ayanamsa, ayanamsaValue, houseSystem, nodeType
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(engineVersion, forKey: .engineVersion)
        try container.encode(exportDate, forKey: .exportDate)
        try container.encode(ayanamsa, forKey: .ayanamsa)
        try container.encode(ayanamsaValue, forKey: .ayanamsaValue)
        try container.encode(houseSystem, forKey: .houseSystem)
        try container.encode(nodeType, forKey: .nodeType)
    }
}

public struct BirthDataExport: Codable, Sendable {
    public let name: String
    public let dateTimeUTC: Date
    public let timeZoneOffsetSeconds: Double
    public let timeZoneOffsetHours: String
    public let latitude: Double
    public let longitude: Double
    public let hasBirthTime: Bool

    enum CodingKeys: String, CodingKey {
        case name, dateTimeUTC, timeZoneOffsetSeconds, timeZoneOffsetHours, latitude, longitude, hasBirthTime
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(dateTimeUTC, forKey: .dateTimeUTC)
        try container.encode(timeZoneOffsetSeconds, forKey: .timeZoneOffsetSeconds)
        try container.encode(timeZoneOffsetHours, forKey: .timeZoneOffsetHours)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(hasBirthTime, forKey: .hasBirthTime)
    }
}

public struct RasiChartExport: Codable, Sendable {
    public let ascendant: AscendantExport?
    public let planets: [PlanetExport]
    public let houseCusps: [Double]?

    enum CodingKeys: String, CodingKey {
        case ascendant, planets, houseCusps
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(ascendant, forKey: .ascendant)
        try container.encode(planets, forKey: .planets)
        try container.encodeIfPresent(houseCusps, forKey: .houseCusps)
    }
}

public struct AscendantExport: Codable, Sendable {
    public let sign: String
    public let degree: String
    public let longitude: Double
    public let nakshatra: String
    public let pada: Int

    enum CodingKeys: String, CodingKey {
        case sign, degree, longitude, nakshatra, pada
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sign, forKey: .sign)
        try container.encode(degree, forKey: .degree)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(nakshatra, forKey: .nakshatra)
        try container.encode(pada, forKey: .pada)
    }
}

public struct PlanetExport: Codable, Sendable {
    public let planet: String
    public let sign: String
    public let longitude: Double
    public let degreeInSign: String
    public let nakshatra: String
    public let pada: Int
    public let house: Int?
    public let isRetrograde: Bool

    enum CodingKeys: String, CodingKey {
        case planet, sign, longitude, degreeInSign, nakshatra, pada, house, isRetrograde
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(planet, forKey: .planet)
        try container.encode(sign, forKey: .sign)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(degreeInSign, forKey: .degreeInSign)
        try container.encode(nakshatra, forKey: .nakshatra)
        try container.encode(pada, forKey: .pada)
        try container.encodeIfPresent(house, forKey: .house)
        try container.encode(isRetrograde, forKey: .isRetrograde)
    }
}

public struct VargaExport: Codable, Sendable {
    public let division: Int
    public let name: String
    public let shortName: String
    public let ascendantSign: String?
    public let placements: [VargaPlacement]

    public struct VargaPlacement: Codable, Sendable {
        public let planet: String
        public let sign: String

        enum CodingKeys: String, CodingKey {
            case planet, sign
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(planet, forKey: .planet)
            try container.encode(sign, forKey: .sign)
        }
    }

    enum CodingKeys: String, CodingKey {
        case division, name, shortName, ascendantSign, placements
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(division, forKey: .division)
        try container.encode(name, forKey: .name)
        try container.encode(shortName, forKey: .shortName)
        try container.encodeIfPresent(ascendantSign, forKey: .ascendantSign)
        try container.encode(placements, forKey: .placements)
    }

    /// Create from a VargaChart (strips the sourceChart reference)
    public init(from vargaChart: VargaChart) {
        self.division = vargaChart.vargaType.rawValue
        self.name = vargaChart.vargaType.name
        self.shortName = vargaChart.vargaType.shortName
        self.ascendantSign = vargaChart.ascendantSign?.name
        let order: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]
        self.placements = order.compactMap { planet in
            guard let sign = vargaChart.placements[planet] else { return nil }
            return VargaPlacement(planet: planet.rawValue, sign: sign.name)
        }
    }
}

public struct VimshottariDashaExport: Codable, Sendable {
    public let currentDasha: CurrentDashaExport?
    public let mahaDashas: [MahaDashaExport]

    public struct CurrentDashaExport: Codable, Sendable {
        public let asOf: Date
        public let maha: String
        public let antar: String?
        public let pratyantar: String?

        enum CodingKeys: String, CodingKey {
            case asOf, maha, antar, pratyantar
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(asOf, forKey: .asOf)
            try container.encode(maha, forKey: .maha)
            try container.encodeIfPresent(antar, forKey: .antar)
            try container.encodeIfPresent(pratyantar, forKey: .pratyantar)
        }
    }

    public struct MahaDashaExport: Codable, Sendable {
        public let planet: String
        public let startDate: Date
        public let endDate: Date
        public let years: Double
        public let antarDashas: [AntarDashaExport]

        enum CodingKeys: String, CodingKey {
            case planet, startDate, endDate, years, antarDashas
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(planet, forKey: .planet)
            try container.encode(startDate, forKey: .startDate)
            try container.encode(endDate, forKey: .endDate)
            try container.encode(years, forKey: .years)
            try container.encode(antarDashas, forKey: .antarDashas)
        }
    }

    public struct AntarDashaExport: Codable, Sendable {
        public let planet: String
        public let startDate: Date
        public let endDate: Date

        enum CodingKeys: String, CodingKey {
            case planet, startDate, endDate
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(planet, forKey: .planet)
            try container.encode(startDate, forKey: .startDate)
            try container.encode(endDate, forKey: .endDate)
        }
    }

    enum CodingKeys: String, CodingKey {
        case currentDasha, mahaDashas
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(currentDasha, forKey: .currentDasha)
        try container.encode(mahaDashas, forKey: .mahaDashas)
    }
}

public struct JaiminiExport: Codable, Sendable {
    public let charaKarakas: CharaKarakaResult?
    public let karakamsa: KarakamsaResult?
    public let ishtaDevta: IshtaDevtaExport?
    public let arudhaLagnas: ArudhaLagnaResult?

    enum CodingKeys: String, CodingKey {
        case charaKarakas, karakamsa, ishtaDevta, arudhaLagnas
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(charaKarakas, forKey: .charaKarakas)
        try container.encodeIfPresent(karakamsa, forKey: .karakamsa)
        try container.encodeIfPresent(ishtaDevta, forKey: .ishtaDevta)
        try container.encodeIfPresent(arudhaLagnas, forKey: .arudhaLagnas)
    }
}

public struct IshtaDevtaExport: Codable, Sendable {
    public let atmakaraka: String
    public let karakamsaSign: String
    public let twelfthFromKarakamsa: String
    public let planetsInTwelfth: [String]
    public let significator: String
    public let deity: DeityExport

    public struct DeityExport: Codable, Sendable {
        public let primary: String
        public let alternates: [String]
        public let theme: String

        enum CodingKeys: String, CodingKey {
            case primary, alternates, theme
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(primary, forKey: .primary)
            try container.encode(alternates, forKey: .alternates)
            try container.encode(theme, forKey: .theme)
        }
    }

    enum CodingKeys: String, CodingKey {
        case atmakaraka, karakamsaSign, twelfthFromKarakamsa, planetsInTwelfth, significator, deity
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(atmakaraka, forKey: .atmakaraka)
        try container.encode(karakamsaSign, forKey: .karakamsaSign)
        try container.encode(twelfthFromKarakamsa, forKey: .twelfthFromKarakamsa)
        try container.encode(planetsInTwelfth, forKey: .planetsInTwelfth)
        try container.encode(significator, forKey: .significator)
        try container.encode(deity, forKey: .deity)
    }
}

public struct SpecialPointsExport: Codable, Sendable {
    public let bhriguBindu: BhriguBinduResult?
    public let pushkara: PushkaraResult?

    enum CodingKeys: String, CodingKey {
        case bhriguBindu
        case pushkara
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(bhriguBindu, forKey: .bhriguBindu)
        try container.encodeIfPresent(pushkara, forKey: .pushkara)
    }
}
