import Foundation

/// A single dasha period (Maha, Antar, or Pratyantar level).
/// Tree structure: Maha contains Antar sub-periods, Antar contains Pratyantar sub-periods.
public struct DashaPeriod: Codable, Sendable {
    /// Planet ruling this period
    public let planet: Planet
    /// Start date (UTC)
    public let startDate: Date
    /// End date (UTC)
    public let endDate: Date
    /// Dasha level
    public let level: Level
    /// Sub-periods within this period
    public let subPeriods: [DashaPeriod]

    public enum Level: String, Codable, Sendable {
        case maha = "Maha Dasha"
        case antar = "Antar Dasha"
        case pratyantar = "Pratyantar Dasha"
    }

    /// Duration in days
    public var durationDays: Double {
        endDate.timeIntervalSince(startDate) / 86400.0
    }

    /// Whether a given date falls within this period
    public func contains(date: Date) -> Bool {
        date >= startDate && date < endDate
    }

    /// Find the active sub-period at a given date (returns nil if date is outside this period)
    public func activeSubPeriod(at date: Date) -> DashaPeriod? {
        subPeriods.first { $0.contains(date: date) }
    }

    /// Print summary with indentation
    public func printSummary(indent: Int = 0) {
        let pad = String(repeating: "  ", count: indent)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")
        print("\(pad)\(planet.rawValue) \(level.rawValue): \(df.string(from: startDate)) to \(df.string(from: endDate))")
        for sub in subPeriods {
            sub.printSummary(indent: indent + 1)
        }
    }
}
