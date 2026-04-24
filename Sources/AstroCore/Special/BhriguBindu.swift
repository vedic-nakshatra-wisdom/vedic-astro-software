import Foundation

/// Bhrigu Bindu — the midpoint of Moon and Rahu in the birth chart.
///
/// This is a highly sensitive point in Vedic astrology. When any planet
/// transits over the Bhrigu Bindu degree (in Sarvashtakavarga), significant
/// events tend to manifest. The SAV score at the Bhrigu Bindu sign indicates
/// the nature of results (high SAV = favorable).
public struct BhriguBinduResult: Codable, Sendable {
    /// The Bhrigu Bindu longitude (sidereal, 0–360°)
    public let longitude: Double
    /// Sign the Bhrigu Bindu falls in
    public let sign: Sign
    /// Degree within the sign (0–30°)
    public let degreeInSign: Double
    /// Nakshatra the Bhrigu Bindu falls in
    public let nakshatra: Nakshatra
    /// Nakshatra pada (1–4)
    public let pada: Int
    /// House placement (1–12, Whole Sign from Lagna)
    public let house: Int?
    /// SAV score at the Bhrigu Bindu sign (if Ashtakavarga provided)
    public let savScore: Int?

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case longitude, sign, degreeInSign, nakshatra, pada, house, savScore
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(sign, forKey: .sign)
        try container.encode(degreeInSign, forKey: .degreeInSign)
        try container.encode(nakshatra, forKey: .nakshatra)
        try container.encode(pada, forKey: .pada)
        try container.encodeIfPresent(house, forKey: .house)
        try container.encodeIfPresent(savScore, forKey: .savScore)
    }

    /// Formatted position string
    public var formattedPosition: String {
        let deg = degreeInSign
        let d = Int(deg)
        let mFull = (deg - Double(d)) * 60.0
        let m = Int(mFull)
        let s = Int((mFull - Double(m)) * 60.0)
        return "\(sign.name) \(d)°\(String(format: "%02d", m))'\(String(format: "%02d", s))\""
    }
}

/// Computes the Bhrigu Bindu (Moon-Rahu midpoint).
public struct BhriguBinduCalculator: Sendable {

    public init() {}

    /// Compute Bhrigu Bindu. Optionally accepts Ashtakavarga for SAV score.
    public func compute(
        from chart: BirthChart,
        ashtakavarga: AshtakavargaResult? = nil
    ) -> BhriguBinduResult? {
        guard let moonLong = chart.position(of: .moon)?.longitude,
              let rahuLong = chart.position(of: .rahu)?.longitude else { return nil }

        // Midpoint: shorter arc between Moon and Rahu
        let bb = midpoint(moonLong, rahuLong)

        let sign = Sign.from(longitude: bb)
        let signIndex = sign.rawValue
        let degreeInSign = bb - Double(signIndex) * 30.0
        let nakInfo = Nakshatra.from(longitude: bb)

        // House placement (Whole Sign)
        let house: Int?
        if let lagnaIndex = chart.ascendant?.signIndex {
            house = ((signIndex - lagnaIndex + 12) % 12) + 1
        } else {
            house = nil
        }

        // SAV score at BB's sign
        let savScore: Int?
        if let sav = ashtakavarga {
            savScore = sav.sarvashtakavarga.bindus[signIndex]
        } else {
            savScore = nil
        }

        return BhriguBinduResult(
            longitude: bb,
            sign: sign,
            degreeInSign: degreeInSign,
            nakshatra: nakInfo.nakshatra,
            pada: nakInfo.pada,
            house: house,
            savScore: savScore
        )
    }

    /// Midpoint along the shorter arc between two longitudes.
    private func midpoint(_ a: Double, _ b: Double) -> Double {
        let diff = ((b - a).truncatingRemainder(dividingBy: 360.0) + 360.0)
            .truncatingRemainder(dividingBy: 360.0)
        let mid: Double
        if diff <= 180.0 {
            mid = a + diff / 2.0
        } else {
            mid = a + (diff - 360.0) / 2.0
        }
        return ((mid.truncatingRemainder(dividingBy: 360.0)) + 360.0)
            .truncatingRemainder(dividingBy: 360.0)
    }
}
