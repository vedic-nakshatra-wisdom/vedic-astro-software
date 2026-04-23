import Foundation

/// Computes Jaimini Chara Karakas from a birth chart.
/// Pure math — no ephemeris calls needed.
public struct CharaKarakaCalculator: Sendable {

    public init() {}

    /// Compute Chara Karakas using the 8-karaka system (default, includes Rahu).
    /// Returns nil if required planet positions are missing.
    public func compute(from chart: BirthChart, useEightKaraka: Bool = true) -> CharaKarakaResult? {
        // Determine which planets participate
        let participants: [Planet]
        if useEightKaraka {
            // 8-karaka: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu
            participants = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu]
        } else {
            // 7-karaka: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn
            participants = Planet.signLords // [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]
        }

        // Build (planet, effectiveDegree) pairs
        var entries: [(planet: Planet, degree: Double)] = []
        for planet in participants {
            guard let pos = chart.planets[planet] else { return nil }

            let degree: Double
            if planet == .rahu {
                // Rahu's degree is inverted: 30 - degreeInSign
                // Because Rahu is always retrograde (enters signs from the end)
                degree = 30.0 - pos.degreeInSign
            } else {
                degree = pos.degreeInSign
            }
            entries.append((planet, degree))
        }

        // Sort descending by degree. Tie-break: standard planetary order
        // (Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn — earlier = higher rank)
        let planetPrecedence: [Planet: Int] = [
            .sun: 0, .moon: 1, .mars: 2, .mercury: 3,
            .jupiter: 4, .venus: 5, .saturn: 6, .rahu: 7
        ]

        entries.sort { a, b in
            if abs(a.degree - b.degree) > 0.0001 {
                return a.degree > b.degree // Higher degree = higher rank
            }
            return (planetPrecedence[a.planet] ?? 99) < (planetPrecedence[b.planet] ?? 99)
        }

        // Assign karakas
        let karakaOrder = useEightKaraka ? CharaKaraka.eightKarakaOrder : CharaKaraka.sevenKarakaOrder

        var karakaMap: [Planet: CharaKaraka] = [:]
        var planetMap: [CharaKaraka: Planet] = [:]
        var ranking: [CharaKarakaResult.KarakaRanking] = []

        for (i, entry) in entries.enumerated() {
            guard i < karakaOrder.count else { break }
            let karaka = karakaOrder[i]
            karakaMap[entry.planet] = karaka
            planetMap[karaka] = entry.planet
            ranking.append(CharaKarakaResult.KarakaRanking(
                planet: entry.planet,
                degreeInSign: entry.degree,
                karaka: karaka
            ))
        }

        return CharaKarakaResult(
            karakas: karakaMap,
            planets: planetMap,
            isEightKaraka: useEightKaraka,
            ranking: ranking
        )
    }
}
