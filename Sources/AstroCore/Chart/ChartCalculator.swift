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

        if birthData.hasBirthTime {
            if let houses = await ephemeris.calcHouses(
                julianDay: jd,
                latitude: birthData.latitude,
                longitude: birthData.longitude,
                houseSystem: houseSystem.seCode
            ) {
                houseCusps = houses.cusps
                ascendant = PlanetaryPosition(
                    planet: .sun, // placeholder -- ascendant is not a planet
                    longitude: houses.ascendant,
                    latitude: 0,
                    speedLongitude: 0,
                    distance: 0
                )
            }
        }

        // 6. Build and return BirthChart
        return BirthChart(
            birthData: birthData,
            julianDay: jd,
            planets: positions,
            ascendant: ascendant,
            houseCusps: houseCusps,
            houseSystem: houseSystem,
            ayanamsaType: ayanamsa,
            ayanamsaValue: ayanamsaValue,
            nodeType: nodeType,
            sunrise: nil,  // TODO: v0.2
            sunset: nil    // TODO: v0.2
        )
    }
}
