import Foundation

/// Planetary positions in a divisional chart.
/// Each planet's longitude is mapped to a varga sign, but the degree within
/// the varga sign has no standard meaning — only the sign placement matters.
public struct VargaChart: Sendable {
    /// Which varga this chart represents
    public let vargaType: VargaType
    /// Sign placement for each planet (0-based sign index)
    public let placements: [Planet: Sign]
    /// Source D1 chart
    public let sourceChart: BirthChart
    /// Ascendant varga sign (if birth time known)
    public let ascendantSign: Sign?

    /// Get varga sign for a planet
    public func sign(of planet: Planet) -> Sign? {
        placements[planet]
    }

    /// All planets in a given sign
    public func planetsIn(sign: Sign) -> [Planet] {
        Planet.allCases.filter { placements[$0] == sign }
    }

    /// Print summary
    public func printSummary() {
        print("\(vargaType.name) (\(vargaType.shortName)) Chart")
        if let asc = ascendantSign {
            print("Lagna: \(asc.name)")
        }
        let order: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]
        for planet in order {
            if let sign = placements[planet] {
                print("  \(planet.rawValue.padding(toLength: 9, withPad: " ", startingAt: 0)) \(sign.name)")
            }
        }
    }
}
