import Foundation

/// Bhava Chalit chart result — equal house system where the ascendant degree
/// is the midpoint (bhava madhya) of the 1st house, each house spans exactly 30°.
public struct BhavaChalitResult: Codable, Sendable {
    /// Bhava cusps (sandhi points) — 12 values, cusp[i] = start of house i+1
    public let cusps: [Double]
    /// Bhava madhya (midpoints) — 12 values, madhya[i] = midpoint of house i+1
    public let madhyas: [Double]
    /// Planet-to-bhava mapping (1-12)
    public let planetBhava: [Planet: Int]

    /// Planets in a given bhava (1-12)
    public func planetsIn(bhava: Int) -> [Planet] {
        planetBhava.filter { $0.value == bhava }.map(\.key)
    }

    /// Whether a planet has shifted from its rasi house to a different bhava
    public func hasShifted(planet: Planet, rasiHouse: Int?) -> Bool {
        guard let rasi = rasiHouse, let bhava = planetBhava[planet] else { return false }
        return rasi != bhava
    }
}

/// Computes the Bhava Chalit (equal house) chart.
public struct BhavaChalitCalculator: Sendable {

    public init() {}

    /// Compute Bhava Chalit from a birth chart. Returns nil if no birth time.
    public func compute(from chart: BirthChart) -> BhavaChalitResult? {
        guard let ascLon = chart.ascendant?.longitude else { return nil }

        // Bhava Madhya: midpoint of house N = Asc + (N-1) * 30
        var madhyas: [Double] = []
        for i in 0..<12 {
            let m = (ascLon + Double(i) * 30.0).truncatingRemainder(dividingBy: 360.0)
            madhyas.append(m)
        }

        // Bhava Sandhi (cusps): boundary between houses
        // Cusp of house N = Madhya(N) - 15° = Asc + (N-1)*30 - 15
        var cusps: [Double] = []
        for i in 0..<12 {
            let c = (ascLon + Double(i) * 30.0 - 15.0 + 360.0).truncatingRemainder(dividingBy: 360.0)
            cusps.append(c)
        }

        // Assign planets to bhavas
        var planetBhava: [Planet: Int] = [:]
        for planet in Planet.allCases {
            guard let pos = chart.position(of: planet) else { continue }
            planetBhava[planet] = bhavaFor(longitude: pos.longitude, cusps: cusps)
        }

        return BhavaChalitResult(
            cusps: cusps,
            madhyas: madhyas,
            planetBhava: planetBhava
        )
    }

    /// Determine which bhava (1-12) a longitude falls in, given cusp boundaries.
    private func bhavaFor(longitude: Double, cusps: [Double]) -> Int {
        for i in 0..<12 {
            let start = cusps[i]
            let end = cusps[(i + 1) % 12]
            if end > start {
                if longitude >= start && longitude < end { return i + 1 }
            } else {
                // Wraps around 360°
                if longitude >= start || longitude < end { return i + 1 }
            }
        }
        return 1
    }
}
