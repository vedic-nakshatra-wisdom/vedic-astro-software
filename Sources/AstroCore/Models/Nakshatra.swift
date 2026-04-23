import Foundation

/// The 27 Vedic nakshatras (lunar mansions).
/// Each spans 13°20' (800 arc-minutes) of the zodiac.
public enum Nakshatra: Int, Codable, Sendable, CaseIterable, Hashable {
    case ashwini = 0
    case bharani
    case krittika
    case rohini
    case mrigashira
    case ardra
    case punarvasu
    case pushya
    case ashlesha
    case magha
    case purvaPhalguni
    case uttaraPhalguni
    case hasta
    case chitra
    case swati
    case vishakha
    case anuradha
    case jyeshtha
    case mula
    case purvaAshadha
    case uttaraAshadha
    case shravana
    case dhanishtha
    case shatabhisha
    case purvaBhadrapada
    case uttaraBhadrapada
    case revati

    /// Span of each nakshatra in degrees
    public static let span: Double = 360.0 / 27.0 // 13.3333°

    /// Span of each pada in degrees
    public static let padaSpan: Double = span / 4.0 // 3.3333°

    public var name: String {
        switch self {
        case .ashwini: return "Ashwini"
        case .bharani: return "Bharani"
        case .krittika: return "Krittika"
        case .rohini: return "Rohini"
        case .mrigashira: return "Mrigashira"
        case .ardra: return "Ardra"
        case .punarvasu: return "Punarvasu"
        case .pushya: return "Pushya"
        case .ashlesha: return "Ashlesha"
        case .magha: return "Magha"
        case .purvaPhalguni: return "Purva Phalguni"
        case .uttaraPhalguni: return "Uttara Phalguni"
        case .hasta: return "Hasta"
        case .chitra: return "Chitra"
        case .swati: return "Swati"
        case .vishakha: return "Vishakha"
        case .anuradha: return "Anuradha"
        case .jyeshtha: return "Jyeshtha"
        case .mula: return "Mula"
        case .purvaAshadha: return "Purva Ashadha"
        case .uttaraAshadha: return "Uttara Ashadha"
        case .shravana: return "Shravana"
        case .dhanishtha: return "Dhanishtha"
        case .shatabhisha: return "Shatabhisha"
        case .purvaBhadrapada: return "Purva Bhadrapada"
        case .uttaraBhadrapada: return "Uttara Bhadrapada"
        case .revati: return "Revati"
        }
    }

    /// Vimshottari dasha lord for this nakshatra
    public var dashaLord: Planet {
        // Cycle: Ketu(0), Venus(1), Sun(2), Moon(3), Mars(4), Rahu(5), Jupiter(6), Saturn(7), Mercury(8)
        let dashaOrder: [Planet] = [.ketu, .venus, .sun, .moon, .mars, .rahu, .jupiter, .saturn, .mercury]
        return dashaOrder[rawValue % 9]
    }

    /// Compute nakshatra and pada from a sidereal longitude
    public static func from(longitude: Double) -> (nakshatra: Nakshatra, pada: Int) {
        let normalizedLon = longitude.truncatingRemainder(dividingBy: 360.0)
        let lon = normalizedLon < 0 ? normalizedLon + 360.0 : normalizedLon

        let nakIndex = Int(lon / span)
        let posInNak = lon - Double(nakIndex) * span
        let pada = min(Int(posInNak / padaSpan) + 1, 4) // 1-4

        return (Nakshatra(rawValue: nakIndex % 27)!, pada)
    }

    /// Fraction of nakshatra elapsed (0.0 = start, 1.0 = end)
    public static func fractionElapsed(at longitude: Double) -> Double {
        let normalizedLon = longitude.truncatingRemainder(dividingBy: 360.0)
        let lon = normalizedLon < 0 ? normalizedLon + 360.0 : normalizedLon
        let nakIndex = Int(lon / span)
        let posInNak = lon - Double(nakIndex) * span
        return posInNak / span
    }
}
