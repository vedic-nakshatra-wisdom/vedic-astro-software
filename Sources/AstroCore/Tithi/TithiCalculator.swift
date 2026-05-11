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

    /// Compute tithi and estimated end time at a given moment.
    private func tithiAtMoment(
        date: Date, ephemeris: EphemerisActor
    ) async -> (tithi: Tithi, angle: Double, moonLon: Double, sunLon: Double,
                moonSpeed: Double, sunSpeed: Double, estimatedEnd: Date?) {
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

        let moonResult = await ephemeris.calcUT(body: 1, at: jd)  // SE_MOON
        let moonLon = moonResult?.longitude ?? 0
        let moonSpeed = moonResult?.speedLon ?? 13.2

        let sunResult = await ephemeris.calcUT(body: 0, at: jd)   // SE_SUN
        let sunLon = sunResult?.longitude ?? 0
        let sunSpeed = sunResult?.speedLon ?? 1.0

        var angle = moonLon - sunLon
        if angle < 0 { angle += 360.0 }

        let tithiIndex = Int(angle / 12.0) % 30
        let tithi = Tithi(rawValue: tithiIndex)!

        let relativeSpeed = moonSpeed - sunSpeed
        let nextBoundary = Double(tithiIndex + 1) * 12.0
        let remainingDegrees = nextBoundary - angle
        let estimatedEnd: Date?
        if relativeSpeed > 0 {
            let daysToEnd = remainingDegrees / relativeSpeed
            estimatedEnd = date.addingTimeInterval(daysToEnd * 86400.0)
        } else {
            estimatedEnd = nil
        }

        return (tithi, angle, moonLon, sunLon, moonSpeed, sunSpeed, estimatedEnd)
    }

    private func computeDay(
        date: Date, dayOfMonth: Int, timeZone: TimeZone, ephemeris: EphemerisActor
    ) async -> DayTithiInfo {
        // Sunrise data (6 AM local)
        let sunrise = await tithiAtMoment(date: date, ephemeris: ephemeris)
        let moonLon = sunrise.moonLon
        let sunLon = sunrise.sunLon
        let angle = sunrise.angle
        let tithi = sunrise.tithi
        let nextTithi = Tithi(rawValue: (tithi.rawValue + 1) % 30)!
        let progress = (angle - Double(tithi.rawValue) * 12.0) / 12.0

        // Compute tithi segments for this day
        let nextDayStart = date.addingTimeInterval(86400) // next day 6 AM
        let midnight = date.addingTimeInterval(18 * 3600) // approximate midnight

        var segments: [TithiSegment] = []
        var currentTime = date
        var iterations = 0
        var lastTithiRaw: Int = -1

        while currentTime < nextDayStart && iterations < 5 {
            iterations += 1
            let moment = await tithiAtMoment(date: currentTime, ephemeris: ephemeris)

            // Skip duplicate: linear estimate wasn't precise enough, same tithi reappears
            if moment.tithi.rawValue == lastTithiRaw {
                if let endDate = moment.estimatedEnd, endDate < nextDayStart {
                    // Re-estimate was still same tithi — advance past it
                    currentTime = endDate.addingTimeInterval(120)
                    continue
                } else {
                    break
                }
            }

            lastTithiRaw = moment.tithi.rawValue

            if let endDate = moment.estimatedEnd, endDate < nextDayStart {
                let afterMidnight = endDate > midnight
                segments.append(TithiSegment(
                    tithi: moment.tithi,
                    endDate: endDate,
                    endsAfterMidnight: afterMidnight
                ))
                currentTime = endDate.addingTimeInterval(120) // 2 min past estimated end
            } else {
                segments.append(TithiSegment(
                    tithi: moment.tithi,
                    endDate: nil,
                    endsAfterMidnight: false
                ))
                break
            }
        }

        // Moon sign and nakshatra (at sunrise)
        let moonSign = Sign.from(longitude: moonLon)
        let sunSign = Sign.from(longitude: sunLon)
        let nakshatraIndex = Int(moonLon / (360.0 / 27.0)) % 27
        let nakshatra = Nakshatra(rawValue: nakshatraIndex)?.name ?? ""

        // Karana
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

        // Yoga
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
            segments: segments,
            moonSign: moonSign,
            moonSignSanskrit: moonSign.sanskritName,
            moonNakshatra: nakshatra,
            sunMoonAngle: angle,
            tithiProgress: progress,
            tithiEndDate: sunrise.estimatedEnd,
            karana: karana,
            yoga: yoga,
            moonLongitude: moonLon,
            sunSign: sunSign
        )
    }
}
