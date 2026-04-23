import Foundation

/// Complete chart export bundle — single Codable root for JSON export
/// and input for Markdown formatting.
public struct ChartExport: Codable, Sendable {
    /// Birth data and D1 chart
    public let chart: BirthChart
    /// Divisional chart placements (lightweight, no back-reference)
    public let vargas: [VargaExport]
    /// Vimshottari dasha periods (Maha level with nested Antar/Pratyantar)
    public let dashas: [DashaPeriod]?
    /// Current dasha path at export time (if dashas computed)
    public let currentDasha: CurrentDashaExport?
    /// Ashtakavarga results (BAV + SAV)
    public let ashtakavarga: AshtakavargaResult?
    /// Export metadata
    public let metadata: ExportMetadata

    public struct ExportMetadata: Codable, Sendable {
        public let exportDate: Date
        public let engineVersion: String
        public let ayanamsa: String
        public let houseSystem: String
        public let nodeType: String
    }

    public struct CurrentDashaExport: Codable, Sendable {
        public let date: Date
        public let maha: String
        public let antar: String?
        public let pratyantar: String?
    }
}

/// Lightweight varga export — just the sign placements, no BirthChart back-reference.
public struct VargaExport: Codable, Sendable {
    public let vargaType: VargaType
    public let name: String
    public let shortName: String
    public let ascendantSign: String?
    public let placements: [String: String]  // e.g. {"Sun": "Leo", "Moon": "Gemini"}

    /// Create from a VargaChart (strips the sourceChart reference)
    public init(from vargaChart: VargaChart) {
        self.vargaType = vargaChart.vargaType
        self.name = vargaChart.vargaType.name
        self.shortName = vargaChart.vargaType.shortName
        self.ascendantSign = vargaChart.ascendantSign?.name
        var p: [String: String] = [:]
        for (planet, sign) in vargaChart.placements {
            p[planet.rawValue] = sign.name
        }
        self.placements = p
    }
}
