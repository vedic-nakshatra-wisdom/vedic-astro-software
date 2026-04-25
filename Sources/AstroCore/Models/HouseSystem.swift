import Foundation

/// Supported house systems for chart calculation.
public enum HouseSystem: String, Codable, Sendable, CaseIterable {
    case wholeSign = "Whole Sign"
    case equal = "Equal"
    case sripati = "Sripati"
    case placidus = "Placidus"
    case koch = "Koch"
    case campanus = "Campanus"
    case regiomontanus = "Regiomontanus"
    case porphyry = "Porphyry"

    /// Swiss Ephemeris house system character code
    internal var seCode: Int32 {
        switch self {
        case .wholeSign:      return Int32(Character("W").asciiValue!)
        case .equal:          return Int32(Character("E").asciiValue!)
        case .sripati:        return Int32(Character("S").asciiValue!)
        case .placidus:       return Int32(Character("P").asciiValue!)
        case .koch:           return Int32(Character("K").asciiValue!)
        case .campanus:       return Int32(Character("C").asciiValue!)
        case .regiomontanus:  return Int32(Character("R").asciiValue!)
        case .porphyry:       return Int32(Character("O").asciiValue!)
        }
    }
}

/// Ayanamsa (sidereal mode) selection
public enum AyanamsaType: String, Codable, Sendable, CaseIterable {
    case lahiri = "Lahiri"
    case raman = "Raman"
    case krishnamurti = "Krishnamurti"
    case yukteshwar = "Yukteshwar"
    case trueCitra = "True Chitrapaksha"
    case lahiriICRC = "Lahiri ICRC"

    /// Swiss Ephemeris SE_SIDM_* constant
    public var seMode: Int32 {
        switch self {
        case .lahiri:        return 1
        case .raman:         return 3
        case .krishnamurti:  return 5
        case .yukteshwar:    return 7
        case .trueCitra:     return 27
        case .lahiriICRC:    return 46
        }
    }
}

/// True Node vs Mean Node for Rahu/Ketu
public enum NodeType: String, Codable, Sendable {
    case trueNode = "True Node"
    case meanNode = "Mean Node"

    /// Swiss Ephemeris body constant for Rahu
    public var seBody: Int32 {
        switch self {
        case .trueNode: return 11  // SE_TRUE_NODE
        case .meanNode: return 10  // SE_MEAN_NODE
        }
    }
}
