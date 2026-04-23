import Foundation

/// Computes Vimshottari Dasha periods from a birth chart.
/// Pure calculation — no ephemeris calls needed.
public struct VimshottariCalculator: Sendable {

    /// The standard Vimshottari cycle order (9 planets, 120-year cycle)
    public static let cycleOrder: [Planet] = [
        .ketu, .venus, .sun, .moon, .mars, .rahu, .jupiter, .saturn, .mercury
    ]

    /// Days per year used in calculations (standard in Vedic astrology software)
    public static let daysPerYear: Double = 365.25

    public init() {}

    /// Compute Vimshottari Maha Dasha periods with Antar and Pratyantar sub-periods.
    /// Returns nil if birth time is unknown (Moon position too imprecise for dasha).
    public func computeDashas(
        from chart: BirthChart,
        levels: Int = 3  // 1 = Maha only, 2 = Maha+Antar, 3 = Maha+Antar+Pratyantar
    ) -> [DashaPeriod]? {
        guard chart.birthData.hasBirthTime else { return nil }
        guard let moonPos = chart.planets[.moon] else { return nil }

        let birthDate = chart.birthData.dateTimeUTC
        let moonLongitude = moonPos.longitude

        // 1. Determine starting dasha lord from Moon's nakshatra
        let (nakshatra, _) = Nakshatra.from(longitude: moonLongitude)
        let startingLord = nakshatra.dashaLord

        // 2. Calculate balance of first dasha
        let fractionElapsed = Nakshatra.fractionElapsed(at: moonLongitude)
        let remainingFraction = 1.0 - fractionElapsed

        // 3. Build the cycle starting from the birth nakshatra's lord
        let cycle = Self.cycleOrder
        let startIndex = cycle.firstIndex(of: startingLord)!

        // 4. Generate Maha Dasha periods
        var periods: [DashaPeriod] = []
        var currentDate = birthDate
        let clampedLevels = max(1, min(levels, 3))

        // Generate enough Maha Dashas to cover 120 years (one full cycle)
        for i in 0..<9 {
            let planet = cycle[(startIndex + i) % 9]
            let fullDays = planet.vimshottariYears * Self.daysPerYear

            // First period gets the balance, rest get full duration
            let periodDays: Double
            if i == 0 {
                periodDays = remainingFraction * fullDays
            } else {
                periodDays = fullDays
            }

            let endDate = currentDate.addingTimeInterval(periodDays * 86400.0)

            // Compute sub-periods
            let subPeriods: [DashaPeriod]
            if clampedLevels >= 2 {
                subPeriods = computeSubPeriods(
                    parentPlanet: planet,
                    parentStart: currentDate,
                    parentDurationDays: periodDays,
                    parentLevel: .maha,
                    maxLevel: clampedLevels
                )
            } else {
                subPeriods = []
            }

            periods.append(DashaPeriod(
                planet: planet,
                startDate: currentDate,
                endDate: endDate,
                level: .maha,
                subPeriods: subPeriods
            ))

            currentDate = endDate
        }

        return periods
    }

    /// Compute sub-periods within a parent period.
    /// Antar Dashas cycle starts from the parent Maha lord.
    /// Pratyantar Dashas cycle starts from the parent Antar lord.
    private func computeSubPeriods(
        parentPlanet: Planet,
        parentStart: Date,
        parentDurationDays: Double,
        parentLevel: DashaPeriod.Level,
        maxLevel: Int
    ) -> [DashaPeriod] {
        let subLevel: DashaPeriod.Level
        let currentLevelNum: Int
        switch parentLevel {
        case .maha:
            subLevel = .antar
            currentLevelNum = 2
        case .antar:
            subLevel = .pratyantar
            currentLevelNum = 3
        case .pratyantar:
            return [] // No deeper
        }

        let cycle = Self.cycleOrder
        let startIndex = cycle.firstIndex(of: parentPlanet)!

        var subPeriods: [DashaPeriod] = []
        var currentDate = parentStart

        for i in 0..<9 {
            let planet = cycle[(startIndex + i) % 9]
            // Sub-period duration is proportional: parentDuration * (planet.years / 120)
            let subDays = parentDurationDays * (planet.vimshottariYears / 120.0)
            let endDate = currentDate.addingTimeInterval(subDays * 86400.0)

            // Recurse for deeper levels
            let deeperPeriods: [DashaPeriod]
            if currentLevelNum < maxLevel {
                deeperPeriods = computeSubPeriods(
                    parentPlanet: planet,
                    parentStart: currentDate,
                    parentDurationDays: subDays,
                    parentLevel: subLevel,
                    maxLevel: maxLevel
                )
            } else {
                deeperPeriods = []
            }

            subPeriods.append(DashaPeriod(
                planet: planet,
                startDate: currentDate,
                endDate: endDate,
                level: subLevel,
                subPeriods: deeperPeriods
            ))

            currentDate = endDate
        }

        return subPeriods
    }

    /// Find the active Maha Dasha at a given date.
    public func activeMahaDasha(in dashas: [DashaPeriod], at date: Date) -> DashaPeriod? {
        dashas.first { $0.contains(date: date) }
    }

    /// Find the full active dasha path at a given date (Maha -> Antar -> Pratyantar).
    public func activeDashaPath(in dashas: [DashaPeriod], at date: Date) -> [DashaPeriod] {
        var path: [DashaPeriod] = []
        guard let maha = activeMahaDasha(in: dashas, at: date) else { return path }
        path.append(maha)

        if let antar = maha.activeSubPeriod(at: date) {
            path.append(antar)
            if let pratyantar = antar.activeSubPeriod(at: date) {
                path.append(pratyantar)
            }
        }

        return path
    }
}
