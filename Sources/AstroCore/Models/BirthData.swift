import Foundation

/// Input data for computing a birth chart.
public struct BirthData: Codable, Sendable, Hashable {
    /// Name of the person
    public let name: String
    /// Date and time of birth in UTC
    public let dateTimeUTC: Date
    /// Timezone offset from UTC in seconds (e.g., IST = +19800)
    public let timeZoneOffset: TimeInterval
    /// Geographic latitude in degrees (North positive)
    public let latitude: Double
    /// Geographic longitude in degrees (East positive)
    public let longitude: Double
    /// Altitude in meters (default 0)
    public let altitude: Double
    /// Whether a birth time is known. If false, lagna and houses are omitted.
    public let hasBirthTime: Bool

    public init(
        name: String,
        dateTimeUTC: Date,
        timeZoneOffset: TimeInterval,
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        hasBirthTime: Bool = true
    ) {
        self.name = name
        self.dateTimeUTC = dateTimeUTC
        self.timeZoneOffset = timeZoneOffset
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.hasBirthTime = hasBirthTime
    }

    /// Convenience: create from local date components + IANA timezone identifier.
    /// Uses Apple's TimeZone (backed by the IANA tz database) to resolve the
    /// correct historical UTC offset for the given date. This handles cases like
    /// Nepal switching from UTC+5:30 to UTC+5:45 on 1986-01-01, India's pre-1906
    /// offsets, Sri Lanka's multiple changes, war-time DST, etc.
    ///
    /// - Parameter timeZoneID: IANA identifier, e.g. "Asia/Kathmandu", "Asia/Kolkata"
    public static func from(
        name: String,
        year: Int, month: Int, day: Int,
        hour: Int, minute: Int, second: Int = 0,
        timeZoneID: String,
        latitude: Double,
        longitude: Double,
        altitude: Double = 0
    ) -> BirthData {
        let tz = TimeZone(identifier: timeZoneID)!
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        let localComponents = DateComponents(
            year: year, month: month, day: day,
            hour: hour, minute: minute, second: second
        )
        let localDate = cal.date(from: localComponents)!
        // TimeZone resolves the correct historical offset for this date
        let offsetSeconds = tz.secondsFromGMT(for: localDate)

        return BirthData(
            name: name,
            dateTimeUTC: localDate,  // Calendar already converts to UTC internally
            timeZoneOffset: TimeInterval(offsetSeconds),
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            hasBirthTime: true
        )
    }

    /// Convenience: create from local date components + explicit timezone offset hours.
    /// Use this only when you know the exact offset. Prefer `from(timeZoneID:)` for
    /// automatic historical timezone resolution.
    public static func from(
        name: String,
        year: Int, month: Int, day: Int,
        hour: Int, minute: Int, second: Int = 0,
        timeZoneHours: Double,
        latitude: Double,
        longitude: Double,
        altitude: Double = 0
    ) -> BirthData {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let localComponents = DateComponents(
            year: year, month: month, day: day,
            hour: hour, minute: minute, second: second
        )
        let localDate = cal.date(from: localComponents)!
        let utcDate = localDate.addingTimeInterval(-timeZoneHours * 3600)

        return BirthData(
            name: name,
            dateTimeUTC: utcDate,
            timeZoneOffset: timeZoneHours * 3600,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            hasBirthTime: true
        )
    }

    /// Decimal hours in UT for Swiss Ephemeris
    internal var utHour: Double {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.hour, .minute, .second], from: dateTimeUTC)
        return Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0 + Double(comps.second ?? 0) / 3600.0
    }

    /// Date components in UT
    internal var utComponents: (year: Int32, month: Int32, day: Int32) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day], from: dateTimeUTC)
        return (Int32(comps.year!), Int32(comps.month!), Int32(comps.day!))
    }
}
