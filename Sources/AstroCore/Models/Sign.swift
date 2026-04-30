import Foundation

/// The 12 sidereal zodiac signs (rashis).
public enum Sign: Int, Codable, Sendable, CaseIterable, Hashable {
    case aries = 0
    case taurus
    case gemini
    case cancer
    case leo
    case virgo
    case libra
    case scorpio
    case sagittarius
    case capricorn
    case aquarius
    case pisces

    /// Sign from a sidereal longitude (0-360°)
    public static func from(longitude: Double) -> Sign {
        let index = Int(longitude / 30.0) % 12
        return Sign(rawValue: index)!
    }

    public var name: String {
        switch self {
        case .aries: return "Aries"
        case .taurus: return "Taurus"
        case .gemini: return "Gemini"
        case .cancer: return "Cancer"
        case .leo: return "Leo"
        case .virgo: return "Virgo"
        case .libra: return "Libra"
        case .scorpio: return "Scorpio"
        case .sagittarius: return "Sagittarius"
        case .capricorn: return "Capricorn"
        case .aquarius: return "Aquarius"
        case .pisces: return "Pisces"
        }
    }

    /// Sign number (1–12): Aries=1 … Pisces=12
    public var number: Int { rawValue + 1 }

    public var shortName: String {
        switch self {
        case .aries: return "Ari"
        case .taurus: return "Tau"
        case .gemini: return "Gem"
        case .cancer: return "Can"
        case .leo: return "Leo"
        case .virgo: return "Vir"
        case .libra: return "Lib"
        case .scorpio: return "Sco"
        case .sagittarius: return "Sag"
        case .capricorn: return "Cap"
        case .aquarius: return "Aqu"
        case .pisces: return "Pis"
        }
    }

    /// Whether this is an odd sign (masculine): Aries, Gemini, Leo, Libra, Sagittarius, Aquarius
    public var isOdd: Bool { rawValue % 2 == 0 }

    /// Element: Fire (0), Earth (1), Air (2), Water (3)
    public var element: Element { Element(rawValue: rawValue % 4)! }

    /// Quality: Movable/Cardinal (0), Fixed (1), Dual/Mutable (2)
    public var quality: Quality { Quality(rawValue: rawValue % 3)! }

    /// Parashari sign lord
    public var lord: Planet {
        switch self {
        case .aries, .scorpio:        return .mars
        case .taurus, .libra:         return .venus
        case .gemini, .virgo:         return .mercury
        case .cancer:                 return .moon
        case .leo:                    return .sun
        case .sagittarius, .pisces:   return .jupiter
        case .capricorn, .aquarius:   return .saturn
        }
    }

    /// Exaltation sign for each planet
    public static func exaltationSign(of planet: Planet) -> Sign? {
        switch planet {
        case .sun:     return .aries       // 10° Aries
        case .moon:    return .taurus      // 3° Taurus
        case .mars:    return .capricorn   // 28° Capricorn
        case .mercury: return .virgo       // 15° Virgo
        case .jupiter: return .cancer      // 5° Cancer
        case .venus:   return .pisces      // 27° Pisces
        case .saturn:  return .libra       // 20° Libra
        case .rahu:    return .taurus      // Varies by tradition
        case .ketu:    return .scorpio     // Varies by tradition
        }
    }

    /// Debilitation sign for each planet (opposite of exaltation)
    public static func debilitationSign(of planet: Planet) -> Sign? {
        guard let exSign = exaltationSign(of: planet) else { return nil }
        return Sign(rawValue: (exSign.rawValue + 6) % 12)
    }

    // MARK: - Varna

    public var varna: Varna {
        switch self {
        case .cancer, .scorpio, .pisces:       return .brahmin
        case .aries, .leo, .sagittarius:       return .kshatriya
        case .taurus, .virgo, .capricorn:      return .vaishya
        case .gemini, .libra, .aquarius:       return .shudra
        }
    }

    // MARK: - Vashya

    /// Vashya category. For Sagittarius and Capricorn which span two categories,
    /// use `vashya(degreeInSign:)` for precision.
    public var vashya: Vashya {
        switch self {
        case .aries, .taurus:       return .chatushpada
        case .gemini, .virgo, .libra, .aquarius: return .manava
        case .cancer, .pisces:      return .jalachara
        case .leo:                  return .vanachara
        case .scorpio:              return .keeta
        case .sagittarius:          return .manava      // 1st half default
        case .capricorn:            return .chatushpada  // 1st half default
        }
    }

    /// Vashya with degree precision for dual-category signs (Sagittarius, Capricorn)
    public func vashya(degreeInSign: Double) -> Vashya {
        switch self {
        case .sagittarius:
            return degreeInSign < 15.0 ? .manava : .chatushpada
        case .capricorn:
            return degreeInSign < 15.0 ? .chatushpada : .jalachara
        default:
            return self.vashya
        }
    }
}

// MARK: - Supporting Enums

public enum Element: Int, Codable, Sendable {
    case fire = 0, earth, air, water
}

public enum Quality: Int, Codable, Sendable {
    case movable = 0, fixed, dual
}

public enum Varna: String, Codable, Sendable {
    case brahmin = "Brahmin"
    case kshatriya = "Kshatriya"
    case vaishya = "Vaishya"
    case shudra = "Shudra"
}

public enum Vashya: String, Codable, Sendable {
    case chatushpada = "Chatushpada"
    case manava = "Manava"
    case jalachara = "Jalachara"
    case vanachara = "Vanachara"
    case keeta = "Keeta"
}
