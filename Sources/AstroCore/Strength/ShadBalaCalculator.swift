import Foundation

/// Computes Shadbala (six-fold strength) for all planets from a BirthChart.
/// Pure math — no ephemeris calls needed.
///
/// Currently computes: Uchcha, Ojhayugmarasi, Kendradi, Drekkana, Dig,
/// Naisargika, and Paksha Bala. Saptavargaja is computed using basic
/// dignity (own sign / exaltation / debilitation) without full friendship tables.
///
/// TODO components (need sunrise/sunset, tropical longitudes):
/// Natonnata, Tribhaga, Abda/Masa/Vara/Hora, Ayana, Cheshta, Drig Bala
public struct ShadBalaCalculator: Sendable {

    public init() {}

    /// Compute Shadbala for all 7 sign-lord planets.
    /// Returns nil if ascendant is not available (no birth time).
    public func compute(from chart: BirthChart) -> ShadBalaResult? {
        guard chart.ascendant != nil else { return nil }

        var results: [Planet: PlanetShadBala] = [:]
        let navamsaType = VargaType.d9

        for planet in Planet.signLords {
            guard let pos = chart.position(of: planet) else { continue }

            let uchcha = uchchaBala(planet: planet, longitude: pos.longitude)
            let saptavargaja = basicSaptavargajaBala(planet: planet, chart: chart)
            let ojha = ojhayugmarasiBala(planet: planet, longitude: pos.longitude, navamsaType: navamsaType)
            let kendra = kendradiBala(planet: planet, chart: chart)
            let drekkana = drekkanaBala(planet: planet, degreeInSign: pos.degreeInSign)
            let dig = digBala(planet: planet, chart: chart)
            let naisargika = naisargikaBala(planet: planet)
            let paksha = pakshaBala(planet: planet, chart: chart)

            results[planet] = PlanetShadBala(
                planet: planet,
                uchchaBala: uchcha,
                saptavargajaBala: saptavargaja,
                ojhayugmarasiBala: ojha,
                kendradiBala: kendra,
                drekkanaBala: drekkana,
                digBala: dig,
                naisargikaBala: naisargika,
                pakshaBala: paksha
            )
        }

        return ShadBalaResult(planetBala: results)
    }

    // MARK: - Uchcha Bala (Exaltation Strength)

    /// Deep exaltation degrees (absolute sidereal longitude) per BPHS
    private static let deepExaltation: [Planet: Double] = [
        .sun: 10.0,       // 10° Aries
        .moon: 33.0,      // 3° Taurus
        .mars: 298.0,     // 28° Capricorn
        .mercury: 165.0,  // 15° Virgo
        .jupiter: 95.0,   // 5° Cancer
        .venus: 357.0,    // 27° Pisces
        .saturn: 200.0    // 20° Libra
    ]

    /// Uchcha Bala: max 60 virupas at exaltation, 0 at debilitation.
    private func uchchaBala(planet: Planet, longitude: Double) -> Double {
        guard let exaltDeg = Self.deepExaltation[planet] else { return 0 }
        let debilDeg = (exaltDeg + 180.0).truncatingRemainder(dividingBy: 360.0)
        var arc = abs(longitude - debilDeg)
        if arc > 180.0 { arc = 360.0 - arc }
        return arc / 3.0  // Max 180/3 = 60
    }

    // MARK: - Saptavargaja Bala (Basic Dignity)

    /// Simplified Saptavargaja: checks own sign, exaltation, debilitation
    /// in D1 only. Full implementation needs friendship tables for 7 vargas.
    private func basicSaptavargajaBala(planet: Planet, chart: BirthChart) -> Double {
        guard let pos = chart.position(of: planet) else { return 0 }
        let sign = pos.sign

        // Own sign
        if sign.lord == planet { return 30.0 }
        // Exaltation sign
        if Sign.exaltationSign(of: planet) == sign { return 20.0 }
        // Debilitation sign
        if Sign.debilitationSign(of: planet) == sign { return 5.0 }

        return 10.0  // Neutral (placeholder until friendship tables)
    }

    // MARK: - Ojhayugmarasi Bala (Odd/Even Sign Strength)

    /// Male planets (Su, Ma, Ju) gain 15 virupas in odd signs.
    /// Female planets (Mo, Ve) gain 15 virupas in even signs.
    /// Mercury and Saturn: odd signs per most traditions.
    /// Checked in both Rasi (D1) and Navamsa (D9).
    private func ojhayugmarasiBala(planet: Planet, longitude: Double, navamsaType: VargaType) -> Double {
        let sign = Sign.from(longitude: longitude)
        let navamsaSignIndex = navamsaType.vargaSignIndex(for: longitude)
        let navamsaSign = Sign(rawValue: navamsaSignIndex)!

        let prefersOdd: Bool
        switch planet {
        case .moon, .venus: prefersOdd = false
        default: prefersOdd = true  // Sun, Mars, Jupiter, Mercury, Saturn
        }

        var total = 0.0
        if prefersOdd == sign.isOdd { total += 15.0 }
        if prefersOdd == navamsaSign.isOdd { total += 15.0 }
        return total
    }

    // MARK: - Kendradi Bala (Angular Strength)

    /// Kendra (1,4,7,10) = 60, Panapara (2,5,8,11) = 30, Apoklima (3,6,9,12) = 15
    private func kendradiBala(planet: Planet, chart: BirthChart) -> Double {
        guard let house = chart.house(of: planet) else { return 0 }
        switch house {
        case 1, 4, 7, 10: return 60.0
        case 2, 5, 8, 11: return 30.0
        default:           return 15.0
        }
    }

    // MARK: - Drekkana Bala (Decanate Strength)

    /// First decanate (0–10°): male planets get 15.
    /// Second decanate (10–20°): neutral planets get 15.
    /// Third decanate (20–30°): female planets get 15.
    private func drekkanaBala(planet: Planet, degreeInSign: Double) -> Double {
        let gender = planetGender(planet)
        let decanate: Int
        if degreeInSign < 10.0 { decanate = 1 }
        else if degreeInSign < 20.0 { decanate = 2 }
        else { decanate = 3 }

        switch (decanate, gender) {
        case (1, .male), (2, .neutral), (3, .female):
            return 15.0
        default:
            return 0.0
        }
    }

    private enum PlanetGender { case male, female, neutral }

    private func planetGender(_ planet: Planet) -> PlanetGender {
        switch planet {
        case .sun, .mars, .jupiter: return .male
        case .moon, .venus: return .female
        case .mercury, .saturn: return .neutral
        default: return .neutral
        }
    }

    // MARK: - Dig Bala (Directional Strength)

    /// Each planet is strongest in a specific house (direction):
    /// Jupiter/Mercury → 1st (East), Sun/Mars → 10th (South),
    /// Saturn → 7th (West), Moon/Venus → 4th (North).
    /// Max 60 virupas when in strongest house, 0 when opposite.
    private func digBala(planet: Planet, chart: BirthChart) -> Double {
        guard let house = chart.house(of: planet),
              chart.ascendant != nil else { return 0 }

        // Reference longitude for the strongest house
        let strongHouse: Int
        switch planet {
        case .jupiter, .mercury: strongHouse = 1
        case .sun, .mars:        strongHouse = 10
        case .saturn:            strongHouse = 7
        case .moon, .venus:      strongHouse = 4
        default:                 return 0
        }

        // In Whole Sign, calculate angular distance from the midpoint of the strong house
        // Using house-number based calculation: distance in houses from strong point
        let houseDistance = ((house - strongHouse + 12) % 12)
        // Convert house distance to degrees (each house = 30°)
        let arcDeg = Double(houseDistance) * 30.0
        let effectiveArc = arcDeg > 180.0 ? 360.0 - arcDeg : arcDeg
        return (180.0 - effectiveArc) / 3.0
    }

    // MARK: - Naisargika Bala (Natural Strength)

    /// Fixed natural strength per BPHS. Sun strongest, Saturn weakest.
    /// Values in virupas: each planet is 1/7 rupa apart.
    private func naisargikaBala(planet: Planet) -> Double {
        switch planet {
        case .sun:     return 60.0
        case .moon:    return 51.43
        case .venus:   return 42.86
        case .jupiter: return 34.29
        case .mercury: return 25.71
        case .mars:    return 17.14
        case .saturn:  return 8.57
        default:       return 0
        }
    }

    // MARK: - Paksha Bala (Lunar Phase Strength)

    /// Based on Sun-Moon angular distance.
    /// Shukla Paksha (waxing): benefics gain; Krishna Paksha: malefics gain.
    /// Raw value = |Moon - Sun| / 3 (if > 180, use 360 - diff)
    /// Benefics get raw; malefics get (60 - raw).
    private func pakshaBala(planet: Planet, chart: BirthChart) -> Double {
        guard let moonLong = chart.position(of: .moon)?.longitude,
              let sunLong = chart.position(of: .sun)?.longitude else { return 0 }

        var diff = moonLong - sunLong
        if diff < 0 { diff += 360.0 }
        // diff is now 0–360, where 0–180 = waxing, 180–360 = waning

        let rawBala: Double
        if diff <= 180.0 {
            rawBala = diff / 3.0  // Waxing: 0–60
        } else {
            rawBala = (360.0 - diff) / 3.0  // Waning: 60–0
        }

        let isBenefic: Bool
        switch planet {
        case .jupiter, .venus, .moon, .mercury: isBenefic = true
        default: isBenefic = false
        }

        return isBenefic ? rawBala : (60.0 - rawBala)
    }
}
