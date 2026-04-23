import Foundation

/// Computes Ashtakavarga (BAV + SAV) from a birth chart.
/// Pure math -- no ephemeris calls needed.
public struct AshtakavargaCalculator: Sendable {

    public init() {}

    /// Compute complete Ashtakavarga for a chart.
    /// Requires ascendant (returns nil if birth time unknown).
    public func compute(from chart: BirthChart) -> AshtakavargaResult? {
        guard let ascendant = chart.ascendant else { return nil }

        let ascSignIndex = ascendant.signIndex

        // Build sign index lookup for all planets
        var signIndices: [Planet: Int] = [:]
        for (planet, pos) in chart.planets {
            signIndices[planet] = pos.signIndex
        }

        // Compute BAV for each of the 7 Ashtakavarga planets
        var bavResults: [Planet: Bhinnashtakavarga] = [:]

        for planet in Planet.ashtakavargaPlanets {
            guard let table = AshtakavargaData.tables[planet] else { continue }
            var bindus = [Int](repeating: 0, count: 12)

            for (contributor, houses) in table {
                let contributorSignIndex: Int
                switch contributor {
                case .planet(let p):
                    guard let idx = signIndices[p] else { continue }
                    contributorSignIndex = idx
                case .ascendant:
                    contributorSignIndex = ascSignIndex
                }

                for house in houses {
                    // House 1 = contributor's own sign, house 2 = next sign, etc.
                    let targetSign = (contributorSignIndex + house - 1) % 12
                    bindus[targetSign] += 1
                }
            }

            bavResults[planet] = Bhinnashtakavarga(planet: planet, bindus: bindus)
        }

        // Compute SAV: sum all BAV tables
        var savBindus = [Int](repeating: 0, count: 12)
        for (_, bav) in bavResults {
            for i in 0..<12 {
                savBindus[i] += bav.bindus[i]
            }
        }

        return AshtakavargaResult(
            bpiBindus: bavResults,
            sarvashtakavarga: Sarvashtakavarga(bindus: savBindus)
        )
    }
}
