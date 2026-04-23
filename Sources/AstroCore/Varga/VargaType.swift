import Foundation

/// The 16 Shodasha Vargas (divisional charts) of Parashari astrology.
public enum VargaType: Int, Codable, Sendable, CaseIterable {
    case d1 = 1
    case d2 = 2
    case d3 = 3
    case d4 = 4
    case d7 = 7
    case d9 = 9
    case d10 = 10
    case d12 = 12
    case d16 = 16
    case d20 = 20
    case d24 = 24
    case d27 = 27
    case d30 = 30
    case d40 = 40
    case d45 = 45
    case d60 = 60

    public var name: String {
        switch self {
        case .d1:  return "Rasi"
        case .d2:  return "Hora"
        case .d3:  return "Drekkana"
        case .d4:  return "Chaturthamsa"
        case .d7:  return "Saptamsa"
        case .d9:  return "Navamsa"
        case .d10: return "Dasamsa"
        case .d12: return "Dwadasamsa"
        case .d16: return "Shodasamsa"
        case .d20: return "Vimsamsa"
        case .d24: return "Siddhamsa"
        case .d27: return "Bhamsa"
        case .d30: return "Trimsamsa"
        case .d40: return "Khavedamsa"
        case .d45: return "Akshavedamsa"
        case .d60: return "Shashtiamsa"
        }
    }

    public var shortName: String {
        "D\(rawValue)"
    }

    // MARK: - Core Varga Formula

    /// Compute the varga sign index (0-based, 0=Aries) for a given sidereal longitude.
    public func vargaSignIndex(for longitude: Double) -> Int {
        // Normalize longitude to 0..<360
        let normalizedLong = ((longitude.truncatingRemainder(dividingBy: 360.0)) + 360.0)
            .truncatingRemainder(dividingBy: 360.0)

        let signIndex = Int(normalizedLong / 30.0) % 12
        let degInSign = normalizedLong - Double(signIndex) * 30.0
        let sign = Sign(rawValue: signIndex)!
        let isOdd = sign.isOdd // Aries(0)=true, Taurus(1)=false, etc.

        switch self {
        case .d1:
            return signIndex

        case .d2:
            // Hora: odd sign first half → Leo, second → Cancer
            //        even sign first half → Cancer, second → Leo
            if isOdd {
                return degInSign < 15.0 ? 4 : 3 // Leo : Cancer
            } else {
                return degInSign < 15.0 ? 3 : 4 // Cancer : Leo
            }

        case .d3:
            // Drekkana: trines from sign
            let compartment = min(Int(degInSign / 10.0), 2)
            let trines = [0, 4, 8]
            return (signIndex + trines[compartment]) % 12

        case .d4:
            // Chaturthamsa: kendras from sign
            let compartment = min(Int(degInSign / 7.5), 3)
            let kendras = [0, 3, 6, 9]
            return (signIndex + kendras[compartment]) % 12

        case .d7:
            // Saptamsa
            let compartment = min(Int(degInSign / (30.0 / 7.0)), 6)
            if isOdd {
                return (signIndex + compartment) % 12
            } else {
                return (signIndex + 6 + compartment) % 12
            }

        case .d9:
            // Navamsa: starting sign based on element
            let compartment = min(Int(degInSign / (30.0 / 9.0)), 8)
            let start: Int
            switch sign.element {
            case .fire:  start = 0  // Aries
            case .earth: start = 9  // Capricorn
            case .air:   start = 6  // Libra
            case .water: start = 3  // Cancer
            }
            return (start + compartment) % 12

        case .d10:
            // Dasamsa
            let compartment = min(Int(degInSign / 3.0), 9)
            if isOdd {
                return (signIndex + compartment) % 12
            } else {
                return (signIndex + 8 + compartment) % 12
            }

        case .d12:
            // Dwadasamsa
            let compartment = min(Int(degInSign / 2.5), 11)
            return (signIndex + compartment) % 12

        case .d16:
            // Shodasamsa: start based on quality
            let compartment = min(Int(degInSign / (30.0 / 16.0)), 15)
            let start: Int
            switch sign.quality {
            case .movable: start = 0 // Aries
            case .fixed:   start = 4 // Leo
            case .dual:    start = 8 // Sagittarius
            }
            return (start + compartment) % 12

        case .d20:
            // Vimsamsa: start based on quality
            let compartment = min(Int(degInSign / 1.5), 19)
            let start: Int
            switch sign.quality {
            case .movable: start = 0 // Aries
            case .fixed:   start = 8 // Sagittarius
            case .dual:    start = 4 // Leo
            }
            return (start + compartment) % 12

        case .d24:
            // Siddhamsa
            let compartment = min(Int(degInSign / 1.25), 23)
            let start = isOdd ? 4 : 3 // Leo : Cancer
            return (start + compartment) % 12

        case .d27:
            // Bhamsa: start based on element
            let compartment = min(Int(degInSign / (30.0 / 27.0)), 26)
            let start: Int
            switch sign.element {
            case .fire:  start = 0 // Aries
            case .earth: start = 3 // Cancer
            case .air:   start = 6 // Libra
            case .water: start = 9 // Capricorn
            }
            return (start + compartment) % 12

        case .d30:
            // Trimsamsa: unequal divisions
            return Self.trimsamsaSign(signIndex: signIndex, degInSign: degInSign, isOdd: isOdd)

        case .d40:
            // Khavedamsa
            let compartment = min(Int(degInSign / 0.75), 39)
            let start = isOdd ? 0 : 6 // Aries : Libra
            return (start + compartment) % 12

        case .d45:
            // Akshavedamsa: start based on quality
            let compartment = min(Int(degInSign / (30.0 / 45.0)), 44)
            let start: Int
            switch sign.quality {
            case .movable: start = 0 // Aries
            case .fixed:   start = 4 // Leo
            case .dual:    start = 8 // Sagittarius
            }
            return (start + compartment) % 12

        case .d60:
            // Shashtiamsa
            let compartment = min(Int(degInSign / 0.5), 59)
            return (signIndex + (compartment % 12)) % 12
        }
    }

    // MARK: - Private Helpers

    /// D30 Trimsamsa calculation with unequal sign divisions.
    private static func trimsamsaSign(signIndex: Int, degInSign: Double, isOdd: Bool) -> Int {
        if isOdd {
            // Odd signs: Mars 0-5, Saturn 5-10, Jupiter 10-18, Mercury 18-25, Venus 25-30
            let signs = [0, 10, 8, 2, 6] // Aries, Aquarius, Sagittarius, Gemini, Libra
            let boundaries: [Double] = [0, 5, 10, 18, 25, 30]
            for i in 0..<5 {
                if degInSign < boundaries[i + 1] {
                    return signs[i]
                }
            }
            return signs[4] // Last bucket
        } else {
            // Even signs: Venus 0-5, Mercury 5-12, Jupiter 12-20, Saturn 20-25, Mars 25-30
            let signs = [1, 5, 11, 9, 7] // Taurus, Virgo, Pisces, Capricorn, Scorpio
            let boundaries: [Double] = [0, 5, 12, 20, 25, 30]
            for i in 0..<5 {
                if degInSign < boundaries[i + 1] {
                    return signs[i]
                }
            }
            return signs[4] // Last bucket
        }
    }
}
