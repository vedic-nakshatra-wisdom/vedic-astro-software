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

    // MARK: - Gana

    public var gana: Gana {
        switch self {
        case .ashwini, .mrigashira, .punarvasu, .pushya, .hasta, .swati, .anuradha, .shravana, .revati:
            return .deva
        case .bharani, .rohini, .ardra, .purvaPhalguni, .uttaraPhalguni, .purvaAshadha, .uttaraAshadha, .purvaBhadrapada, .uttaraBhadrapada:
            return .manushya
        case .krittika, .ashlesha, .magha, .chitra, .vishakha, .jyeshtha, .mula, .dhanishtha, .shatabhisha:
            return .rakshasa
        }
    }

    // MARK: - Yoni

    public var yoni: (animal: YoniAnimal, gender: YoniGender) {
        switch self {
        case .ashwini:          return (.horse, .male)
        case .bharani:          return (.elephant, .male)
        case .krittika:         return (.sheep, .female)
        case .rohini:           return (.serpent, .male)
        case .mrigashira:       return (.serpent, .female)
        case .ardra:            return (.dog, .female)
        case .punarvasu:        return (.cat, .female)
        case .pushya:           return (.sheep, .male)
        case .ashlesha:         return (.cat, .male)
        case .magha:            return (.rat, .male)
        case .purvaPhalguni:    return (.rat, .female)
        case .uttaraPhalguni:   return (.cow, .male)
        case .hasta:            return (.buffalo, .male)
        case .chitra:           return (.tiger, .female)
        case .swati:            return (.buffalo, .female)
        case .vishakha:         return (.tiger, .male)
        case .anuradha:         return (.deer, .female)
        case .jyeshtha:         return (.deer, .male)
        case .mula:             return (.dog, .male)
        case .purvaAshadha:     return (.monkey, .male)
        case .uttaraAshadha:    return (.mongoose, .male)
        case .shravana:         return (.monkey, .female)
        case .dhanishtha:       return (.lion, .female)
        case .shatabhisha:      return (.horse, .female)
        case .purvaBhadrapada:  return (.lion, .male)
        case .uttaraBhadrapada: return (.cow, .female)
        case .revati:           return (.elephant, .female)
        }
    }

    // MARK: - Nadi

    public var nadi: Nadi {
        switch self {
        case .ashwini, .ardra, .punarvasu, .uttaraPhalguni, .hasta, .jyeshtha, .mula, .shatabhisha, .purvaBhadrapada:
            return .adi
        case .bharani, .mrigashira, .pushya, .purvaPhalguni, .chitra, .anuradha, .purvaAshadha, .dhanishtha, .uttaraBhadrapada:
            return .madhya
        case .krittika, .rohini, .ashlesha, .magha, .swati, .vishakha, .uttaraAshadha, .shravana, .revati:
            return .antya
        }
    }

    /// Compute the Tara (birth star compatibility group, 1-9) from a birth nakshatra
    public func tara(from birthNakshatra: Nakshatra) -> Tara {
        let diff = ((self.rawValue - birthNakshatra.rawValue) + 27) % 27
        let taraNum = (diff % 9) + 1
        return Tara(rawValue: taraNum)!
    }
}

// MARK: - Nakshatra Attribute Enums

public enum Gana: String, Codable, Sendable {
    case deva = "Deva"
    case manushya = "Manushya"
    case rakshasa = "Rakshasa"
}

public enum YoniAnimal: String, Codable, Sendable {
    case horse = "Horse"
    case elephant = "Elephant"
    case sheep = "Sheep"
    case serpent = "Serpent"
    case dog = "Dog"
    case cat = "Cat"
    case rat = "Rat"
    case cow = "Cow"
    case buffalo = "Buffalo"
    case tiger = "Tiger"
    case deer = "Deer"
    case monkey = "Monkey"
    case mongoose = "Mongoose"
    case lion = "Lion"
}

public enum YoniGender: String, Codable, Sendable {
    case male = "Male"
    case female = "Female"
}

public enum Nadi: String, Codable, Sendable {
    case adi = "Adi (Vata)"
    case madhya = "Madhya (Pitta)"
    case antya = "Antya (Kapha)"
}

public enum Tara: Int, Codable, Sendable {
    case janma = 1
    case sampat = 2
    case vipat = 3
    case kshema = 4
    case pratyari = 5
    case sadhaka = 6
    case vadha = 7
    case mitra = 8
    case atiMitra = 9

    public var name: String {
        switch self {
        case .janma:    return "Janma"
        case .sampat:   return "Sampat"
        case .vipat:    return "Vipat"
        case .kshema:   return "Kshema"
        case .pratyari: return "Pratyari"
        case .sadhaka:  return "Sadhaka"
        case .vadha:    return "Vadha"
        case .mitra:    return "Mitra"
        case .atiMitra: return "Ati Mitra"
        }
    }
}
