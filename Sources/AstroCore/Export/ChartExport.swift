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
}

// MARK: - Sub-structures

public struct ExportMetadata: Codable, Sendable {
    public let engineVersion: String
    public let exportDate: Date
    public let ayanamsa: String
    public let ayanamsaValue: Double
    public let houseSystem: String
    public let nodeType: String
}

public struct BirthDataExport: Codable, Sendable {
    public let name: String
    public let dateTimeUTC: Date
    public let timeZoneOffsetSeconds: Double
    public let timeZoneOffsetHours: String
    public let latitude: Double
    public let longitude: Double
    public let hasBirthTime: Bool
}

public struct RasiChartExport: Codable, Sendable {
    public let ascendant: AscendantExport?
    public let planets: [PlanetExport]
    public let houseCusps: [Double]?
}

public struct AscendantExport: Codable, Sendable {
    public let sign: String
    public let degree: String
    public let longitude: Double
    public let nakshatra: String
    public let pada: Int
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
    }

    public struct MahaDashaExport: Codable, Sendable {
        public let planet: String
        public let startDate: Date
        public let endDate: Date
        public let years: Double
        public let antarDashas: [AntarDashaExport]
    }

    public struct AntarDashaExport: Codable, Sendable {
        public let planet: String
        public let startDate: Date
        public let endDate: Date
    }
}

public struct JaiminiExport: Codable, Sendable {
    public let charaKarakas: CharaKarakaResult?
    public let karakamsa: KarakamsaResult?
    public let ishtaDevta: IshtaDevtaExport?
    public let arudhaLagnas: ArudhaLagnaResult?
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
    }
}

public struct SpecialPointsExport: Codable, Sendable {
    public let bhriguBindu: BhriguBinduResult?
}
