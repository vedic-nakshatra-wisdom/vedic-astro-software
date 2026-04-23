import Foundation

/// A complete birth chart (D1 rasi chart) with all computed positions.
public struct BirthChart: Codable, Sendable {
    /// Source birth data
    public let birthData: BirthData
    /// Julian Day number used for calculation
    public let julianDay: Double
    /// All 9 planetary positions
    public let planets: [Planet: PlanetaryPosition]
    /// Ascendant (Lagna) position. Nil if birth time unknown.
    public let ascendant: PlanetaryPosition?
    /// House cusp longitudes (12 cusps). Nil if birth time unknown.
    public let houseCusps: [Double]?
    /// House system used
    public let houseSystem: HouseSystem
    /// Ayanamsa type used
    public let ayanamsaType: AyanamsaType
    /// Ayanamsa value in degrees
    public let ayanamsaValue: Double
    /// Node type used (true/mean)
    public let nodeType: NodeType
    /// Sunrise on birth day (UTC). Nil if birth time unknown.
    public let sunrise: Date?
    /// Sunset on birth day (UTC). Nil if birth time unknown.
    public let sunset: Date?

    // MARK: - Convenience Accessors

    /// Get position for a specific planet
    public func position(of planet: Planet) -> PlanetaryPosition? {
        planets[planet]
    }

    /// Lagna sign
    public var lagnaSign: Sign? {
        ascendant?.sign
    }

    /// House number (1-12) for a planet using Whole Sign from Lagna
    public func house(of planet: Planet) -> Int? {
        guard let lagnaIndex = ascendant?.signIndex,
              let planetIndex = planets[planet]?.signIndex else { return nil }
        return ((planetIndex - lagnaIndex + 12) % 12) + 1
    }

    /// Lord of a given house (1-12)
    public func lordOf(house: Int) -> Planet? {
        guard let lagnaIndex = ascendant?.signIndex else { return nil }
        let signIndex = (lagnaIndex + house - 1) % 12
        return Sign(rawValue: signIndex)?.lord
    }

    /// Sign of a given house (1-12)
    public func signOf(house: Int) -> Sign? {
        guard let lagnaIndex = ascendant?.signIndex else { return nil }
        let signIndex = (lagnaIndex + house - 1) % 12
        return Sign(rawValue: signIndex)
    }

    /// All planets in a given house (1-12)
    public func planetsIn(house: Int) -> [Planet] {
        Planet.allCases.filter { self.house(of: $0) == house }
    }

    /// Print a summary of the chart
    public func printSummary() {
        print("Chart for: \(birthData.name)")
        if let asc = ascendant {
            print("Lagna: \(asc.sign.name) \(asc.formattedDegree)")
        }
        print("Ayanamsa: \(ayanamsaType.rawValue) (\(String(format: "%.4f", ayanamsaValue))°)")
        print("Node type: \(nodeType.rawValue)")
        print("")

        let order: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]
        for planet in order {
            if let pos = planets[planet] {
                let houseStr = house(of: planet).map { "H\($0)" } ?? ""
                let nakInfo = "\(pos.nakshatra.name) P\(pos.nakshatraPada)"
                print("  \(planet.rawValue.padding(toLength: 9, withPad: " ", startingAt: 0))"
                    + " \(pos.shortDescription.padding(toLength: 18, withPad: " ", startingAt: 0))"
                    + " \(houseStr.padding(toLength: 4, withPad: " ", startingAt: 0))"
                    + " \(nakInfo)")
            }
        }
    }
}
