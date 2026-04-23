import Foundation

/// Bhinnashtakavarga for a single planet -- bindu counts per sign.
public struct Bhinnashtakavarga: Codable, Sendable {
    /// The planet this BAV belongs to
    public let planet: Planet
    /// Bindu count for each of the 12 signs (0=Aries, index matches Sign.rawValue)
    /// Values range from 0 to 8.
    public let bindus: [Int]

    /// Total bindus (should match the known invariant for this planet)
    public var total: Int { bindus.reduce(0, +) }

    /// Bindus in a specific sign
    public func bindus(in sign: Sign) -> Int {
        bindus[sign.rawValue]
    }
}

/// Sarvashtakavarga -- sum of all 7 Bhinnashtakavarga tables.
public struct Sarvashtakavarga: Codable, Sendable {
    /// Total bindu count for each of the 12 signs.
    /// Values typically range from ~18 to ~38.
    public let bindus: [Int]

    /// Total (should always be 337)
    public var total: Int { bindus.reduce(0, +) }

    /// Bindus in a specific sign
    public func bindus(in sign: Sign) -> Int {
        bindus[sign.rawValue]
    }

    /// Whether a sign is above average (28+)
    public func isStrong(sign: Sign) -> Bool {
        bindus[sign.rawValue] >= 28
    }
}

/// Complete Ashtakavarga result for a chart.
public struct AshtakavargaResult: Codable, Sendable {
    /// Individual planet BAV tables (7 planets)
    public let bpiBindus: [Planet: Bhinnashtakavarga]
    /// Sarvashtakavarga (sum of all BAVs)
    public let sarvashtakavarga: Sarvashtakavarga

    /// Print summary
    public func printSummary() {
        let signs: [Sign] = Sign.allCases
        let signHeaders = signs.map { $0.shortName }

        print("Bhinnashtakavarga (Bindus per Sign)")
        print(String(repeating: "-", count: 70))

        // Header
        var header = "Planet   "
        for s in signHeaders { header += " \(s)" }
        header += "  Total"
        print(header)
        print(String(repeating: "-", count: 70))

        let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]
        for planet in planetOrder {
            if let bav = bpiBindus[planet] {
                var row = planet.rawValue.padding(toLength: 9, withPad: " ", startingAt: 0)
                for b in bav.bindus {
                    row += "  \(String(format: "%2d", b))"
                }
                row += "    \(bav.total)"
                print(row)
            }
        }

        print(String(repeating: "-", count: 70))
        var savRow = "SAV      "
        for b in sarvashtakavarga.bindus {
            savRow += "  \(String(format: "%2d", b))"
        }
        savRow += "    \(sarvashtakavarga.total)"
        print(savRow)
    }
}
