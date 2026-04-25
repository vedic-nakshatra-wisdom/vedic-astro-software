import Foundation
import CSwissEph

/// Main entry point for computing Vedic birth charts.
public struct ChartCalculator: Sendable {

    private let ephemeris: EphemerisActor

    public init(ephemeris: EphemerisActor) {
        self.ephemeris = ephemeris
    }

    /// Compute a complete D1 (Rasi) birth chart.
    public func computeChart(
        for birthData: BirthData,
        houseSystem: HouseSystem = .wholeSign,
        ayanamsa: AyanamsaType = .lahiri,
        nodeType: NodeType = .trueNode
    ) async -> BirthChart {
        // 1. Set sidereal mode
        await ephemeris.setSiderealMode(ayanamsa.seMode)

        // 2. Compute Julian Day from BirthData
        let utc = birthData.utComponents
        let jd = await ephemeris.julianDay(
            year: utc.year, month: utc.month, day: utc.day,
            hour: birthData.utHour
        )

        // 3. Get ayanamsa value
        let ayanamsaValue = await ephemeris.ayanamsaUT(at: jd)

        // 4. Compute all 9 planetary positions
        var positions: [Planet: PlanetaryPosition] = [:]

        for planet in Planet.allCases {
            if planet == .ketu {
                // Ketu = Rahu + 180
                if let rahuPos = positions[.rahu] {
                    let ketuLon = (rahuPos.longitude + 180.0).truncatingRemainder(dividingBy: 360.0)
                    positions[.ketu] = PlanetaryPosition(
                        planet: .ketu,
                        longitude: ketuLon,
                        latitude: -rahuPos.latitude,
                        speedLongitude: rahuPos.speedLongitude,
                        distance: rahuPos.distance
                    )
                }
            } else {
                let seBody: Int32
                if planet == .rahu {
                    seBody = nodeType.seBody
                } else {
                    seBody = planet.seBody!
                }

                if let result = await ephemeris.calcUT(body: seBody, at: jd) {
                    positions[planet] = PlanetaryPosition(
                        planet: planet,
                        longitude: result.longitude,
                        latitude: result.latitude,
                        speedLongitude: result.speedLon,
                        distance: result.distance
                    )
                }
            }
        }

        // 5. Compute houses and ascendant (only if birth time is known)
        var ascendant: PlanetaryPosition? = nil
        var houseCusps: [Double]? = nil
        var mcLongitude: Double? = nil
        var sunrise: Date? = nil
        var sunset: Date? = nil

        if birthData.hasBirthTime {
            if let houses = await ephemeris.calcHouses(
                julianDay: jd,
                latitude: birthData.latitude,
                longitude: birthData.longitude,
                houseSystem: houseSystem.seCode
            ) {
                houseCusps = houses.cusps
                mcLongitude = houses.mc
                ascendant = PlanetaryPosition(
                    planet: .sun, // placeholder -- ascendant is not a planet
                    longitude: houses.ascendant,
                    latitude: 0,
                    speedLongitude: 0,
                    distance: 0
                )
            }

            // 5b. Compute sunrise/sunset for birth day
            // Use start of day (floor JD to noon - 0.5) to find sunrise
            let jdStartOfDay = floor(jd - 0.5) + 0.5  // Previous UT noon
            if let sunriseJD = await ephemeris.riseTransUT(
                julianDay: jdStartOfDay,
                latitude: birthData.latitude,
                longitude: birthData.longitude,
                rise: true
            ) {
                // Convert JD to Date: JD 2451545.0 = 2000-01-01 12:00 UT
                sunrise = Self.dateFromJD(sunriseJD)
            }
            if let sunsetJD = await ephemeris.riseTransUT(
                julianDay: jdStartOfDay,
                latitude: birthData.latitude,
                longitude: birthData.longitude,
                rise: false
            ) {
                sunset = Self.dateFromJD(sunsetJD)
            }
        }

        // 6. Build and return BirthChart
        return BirthChart(
            birthData: birthData,
            julianDay: jd,
            planets: positions,
            ascendant: ascendant,
            houseCusps: houseCusps,
            mc: mcLongitude,
            houseSystem: houseSystem,

            ayanamsaType: ayanamsa,
            ayanamsaValue: ayanamsaValue,
            nodeType: nodeType,
            sunrise: sunrise,
            sunset: sunset
        )
    }

    /// Convert a Julian Day to a Swift Date.
    private static func dateFromJD(_ jd: Double) -> Date {
        // JD 2451545.0 = 2000-01-01 12:00:00 UT (J2000 epoch)
        let j2000: Double = 2451545.0
        let secondsSinceJ2000 = (jd - j2000) * 86400.0
        // J2000 in Unix time = 946728000 (2000-01-01 12:00:00 UTC)
        let unixTime = 946728000.0 + secondsSinceJ2000
        return Date(timeIntervalSince1970: unixTime)
    }
}
