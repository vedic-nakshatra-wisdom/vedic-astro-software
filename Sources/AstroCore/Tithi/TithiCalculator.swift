import Foundation

/// Computes tithi information for every day of a given month.
public struct TithiCalculator: Sendable {
    public init() {}

    /// Compute tithi data for each day of the specified month.
    /// Uses the ephemeris to get Moon and Sun sidereal longitudes at sunrise (~6 AM local) for each day.
    public func computeMonth(
        year: Int, month: Int,
        timeZoneID: String,
        ephemeris: EphemerisActor
    ) async -> MonthTithiData {
        let tz = TimeZone(identifier: timeZoneID) ?? .current
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let startComps = DateComponents(year: year, month: month, day: 1)
        guard let firstDate = cal.date(from: startComps),
              let range = cal.range(of: .day, in: .month, for: firstDate) else {
            return MonthTithiData(year: year, month: month, days: [], firstWeekday: 1)
        }

        let firstWeekday = cal.component(.weekday, from: firstDate)
        var days: [DayTithiInfo] = []

        for day in range {
            let dayComps = DateComponents(year: year, month: month, day: day, hour: 6, minute: 0, second: 0)
            guard let dayDate = cal.date(from: dayComps) else { continue }

            let info = await computeDay(date: dayDate, dayOfMonth: day, timeZone: tz, ephemeris: ephemeris)
            days.append(info)
        }

        return MonthTithiData(year: year, month: month, days: days, firstWeekday: firstWeekday)
    }

    private func computeDay(
        date: Date, dayOfMonth: Int, timeZone: TimeZone, ephemeris: EphemerisActor
    ) async -> DayTithiInfo {
        // Convert to UTC components for Julian Day
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let comps = utcCal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let utHour = Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0 + Double(comps.second ?? 0) / 3600.0

        let jd = await ephemeris.julianDay(
            year: Int32(comps.year ?? 2026),
            month: Int32(comps.month ?? 1),
            day: Int32(comps.day ?? 1),
            hour: utHour
        )

        // Get Moon position
        let moonBody: Int32 = 1  // SE_MOON
        let moonResult = await ephemeris.calcUT(body: moonBody, at: jd)
        let moonLon = moonResult?.longitude ?? 0
        let moonSpeed = moonResult?.speedLon ?? 13.2

        // Get Sun position
        let sunBody: Int32 = 0  // SE_SUN
        let sunResult = await ephemeris.calcUT(body: sunBody, at: jd)
        let sunLon = sunResult?.longitude ?? 0
        let sunSpeed = sunResult?.speedLon ?? 1.0

        // Sun-Moon angle
        var angle = moonLon - sunLon
        if angle < 0 { angle += 360.0 }

        // Tithi
        let tithiIndex = Int(angle / 12.0) % 30
        let tithi = Tithi(rawValue: tithiIndex)!
        let nextTithi = Tithi(rawValue: (tithiIndex + 1) % 30)!
        let progress = (angle - Double(tithiIndex) * 12.0) / 12.0

        // Tithi end time
        let relativeSpeed = moonSpeed - sunSpeed
        let nextBoundary = Double(tithiIndex + 1) * 12.0
        let remainingDegrees = nextBoundary - angle
        let tithiEndDate: Date?
        if relativeSpeed > 0 {
            let daysToEnd = remainingDegrees / relativeSpeed
            tithiEndDate = date.addingTimeInterval(daysToEnd * 86400.0)
        } else {
            tithiEndDate = nil
        }

        // Moon sign and nakshatra
        let moonSign = Sign.from(longitude: moonLon)
        let sunSign = Sign.from(longitude: sunLon)
        let nakshatraIndex = Int(moonLon / (360.0 / 27.0)) % 27
        let nakshatra = Nakshatra(rawValue: nakshatraIndex)?.name ?? ""

        // Karana (half-tithi, each = 6 degrees)
        let karanaIndex = Int(angle / 6.0) % 60
        let karanaNames = [
            "Kimstughna", "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Shakuni", "Chatushpada", "Naaga", "Kimstughna"
        ]
        let karana = karanaNames[min(karanaIndex, karanaNames.count - 1)]

        // Yoga: (Moon longitude + Sun longitude) / (360/27)
        var yogaSum = moonLon + sunLon
        if yogaSum >= 360.0 { yogaSum -= 360.0 }
        let yogaIndex = Int(yogaSum / (360.0 / 27.0)) % 27
        let yogaNames = [
            "Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana",
            "Atiganda", "Sukarma", "Dhriti", "Shula", "Ganda",
            "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra",
            "Siddhi", "Vyatipata", "Variyan", "Parigha", "Shiva",
            "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma",
            "Indra", "Vaidhriti"
        ]
        let yoga = yogaNames[yogaIndex]

        return DayTithiInfo(
            date: date,
            dayOfMonth: dayOfMonth,
            tithi: tithi,
            nextTithi: nextTithi,
            moonSign: moonSign,
            moonSignSanskrit: moonSign.sanskritName,
            moonNakshatra: nakshatra,
            sunMoonAngle: angle,
            tithiProgress: progress,
            tithiEndDate: tithiEndDate,
            karana: karana,
            yoga: yoga,
            moonLongitude: moonLon,
            sunSign: sunSign
        )
    }
}
