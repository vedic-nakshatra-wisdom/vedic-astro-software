import Foundation

// MARK: - Paksha

public enum Paksha: String, Codable, Sendable {
    case shukla = "Shukla"
    case krishna = "Krishna"

    public var displayName: String {
        switch self {
        case .shukla: return "Shukla Paksha"
        case .krishna: return "Krishna Paksha"
        }
    }
}

// MARK: - Tithi

public enum Tithi: Int, Codable, Sendable, CaseIterable {
    case pratipada1 = 0
    case dwitiya1
    case tritiya1
    case chaturthi1
    case panchami1
    case shashthi1
    case saptami1
    case ashtami1
    case navami1
    case dashami1
    case ekadashi1
    case dwadashi1
    case trayodashi1
    case chaturdashi1
    case purnima
    case pratipada2
    case dwitiya2
    case tritiya2
    case chaturthi2
    case panchami2
    case shashthi2
    case saptami2
    case ashtami2
    case navami2
    case dashami2
    case ekadashi2
    case dwadashi2
    case trayodashi2
    case chaturdashi2
    case amavasya

    public var name: String {
        let names = [
            "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
            "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
            "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",
            "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
            "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
            "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya"
        ]
        return names[rawValue]
    }

    /// 1-based tithi day within the paksha (1-15)
    public var tithiDay: Int {
        return (rawValue % 15) + 1
    }

    public var paksha: Paksha {
        return rawValue < 15 ? .shukla : .krishna
    }

    public var deity: String {
        let deities = [
            "Agni", "Brahma", "Gauri", "Ganapati", "Naaga",
            "Kartikeya", "Surya", "Shiva", "Durga", "Yama",
            "Vishnu", "Hari", "Kamadeva", "Shiva", "Chandra",
            "Agni", "Brahma", "Gauri", "Ganapati", "Naaga",
            "Kartikeya", "Surya", "Shiva", "Durga", "Yama",
            "Vishnu", "Hari", "Kamadeva", "Shiva", "Pitri"
        ]
        return deities[rawValue]
    }

    public var moonPhaseIcon: String {
        let day = tithiDay
        let isShukla = paksha == .shukla
        switch day {
        case 1:       return isShukla ? "moonphase.new.moon" : "moonphase.full.moon"
        case 2...4:   return isShukla ? "moonphase.waxing.crescent" : "moonphase.waning.gibbous"
        case 5...8:   return isShukla ? "moonphase.first.quarter" : "moonphase.last.quarter"
        case 9...12:  return isShukla ? "moonphase.waxing.gibbous" : "moonphase.waning.crescent"
        case 13...14: return isShukla ? "moonphase.waxing.gibbous" : "moonphase.waning.crescent"
        case 15:      return isShukla ? "moonphase.full.moon" : "moonphase.new.moon"
        default:      return "moon"
        }
    }

    public static func from(sunMoonAngle: Double) -> Tithi {
        var angle = sunMoonAngle
        if angle < 0 { angle += 360.0 }
        let index = Int(angle / 12.0) % 30
        return Tithi(rawValue: index)!
    }
}

// MARK: - Day Tithi Info

public struct DayTithiInfo: Sendable {
    public let date: Date
    public let dayOfMonth: Int
    public let tithi: Tithi
    public let nextTithi: Tithi
    public let moonSign: Sign
    public let moonSignSanskrit: String
    public let moonNakshatra: String
    public let sunMoonAngle: Double
    public let tithiProgress: Double   // 0-1 within current tithi
    public let tithiEndDate: Date?
    public let karana: String
    public let yoga: String
    public let moonLongitude: Double
    public let sunSign: Sign

    public init(date: Date, dayOfMonth: Int, tithi: Tithi, nextTithi: Tithi,
                moonSign: Sign, moonSignSanskrit: String, moonNakshatra: String,
                sunMoonAngle: Double, tithiProgress: Double, tithiEndDate: Date?,
                karana: String, yoga: String, moonLongitude: Double, sunSign: Sign) {
        self.date = date
        self.dayOfMonth = dayOfMonth
        self.tithi = tithi
        self.nextTithi = nextTithi
        self.moonSign = moonSign
        self.moonSignSanskrit = moonSignSanskrit
        self.moonNakshatra = moonNakshatra
        self.sunMoonAngle = sunMoonAngle
        self.tithiProgress = tithiProgress
        self.tithiEndDate = tithiEndDate
        self.karana = karana
        self.yoga = yoga
        self.moonLongitude = moonLongitude
        self.sunSign = sunSign
    }
}

// MARK: - Month Tithi Data

public struct MonthTithiData: Sendable {
    public let year: Int
    public let month: Int
    public let days: [DayTithiInfo]
    public let firstWeekday: Int  // 1=Sunday, 7=Saturday (Calendar.component .weekday)

    public init(year: Int, month: Int, days: [DayTithiInfo], firstWeekday: Int) {
        self.year = year
        self.month = month
        self.days = days
        self.firstWeekday = firstWeekday
    }

    public var monthName: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = DateComponents(year: year, month: month, day: 1)
        if let date = cal.date(from: comps) {
            return df.string(from: date)
        }
        return "\(month)/\(year)"
    }
}

// MARK: - Sanskrit Sign Names

public extension Sign {
    var sanskritName: String {
        switch self {
        case .aries: return "Mesha"
        case .taurus: return "Vrishabha"
        case .gemini: return "Mithuna"
        case .cancer: return "Karka"
        case .leo: return "Simha"
        case .virgo: return "Kanya"
        case .libra: return "Tula"
        case .scorpio: return "Vrishchika"
        case .sagittarius: return "Dhanu"
        case .capricorn: return "Makara"
        case .aquarius: return "Kumbha"
        case .pisces: return "Meena"
        }
    }
}
