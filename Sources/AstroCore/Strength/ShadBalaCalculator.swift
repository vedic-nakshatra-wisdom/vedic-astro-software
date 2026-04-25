import Foundation

/// Computes Shadbala (six-fold strength) for all 7 sign-lord planets per BPHS Ch.27.
///
/// The six components:
///   1. Sthana Bala (Uchcha, Saptavargaja, Ojhayugmarasi, Kendradi, Drekkana)
///   2. Dig Bala
///   3. Kala Bala (Paksha, Natonnatha, Tribhaga, Abda, Masa, Vara, Hora, Ayana)
///   4. Cheshta Bala (Sun=Ayana, Moon=Paksha, others=Cheshta Kendra)
///   5. Naisargika Bala (fixed natural strength — separate component, NOT part of Kala Bala)
///   6. Drik Bala
public struct ShadBalaCalculator: Sendable {

    public init() {}

    /// Compute Shadbala for all 7 sign-lord planets.
    /// Returns nil if ascendant is not available (no birth time).
    public func compute(from chart: BirthChart) -> ShadBalaResult? {
        guard chart.ascendant != nil else { return nil }

        // Pre-compute vargas needed for Saptavargaja (D1, D2, D3, D7, D9, D12, D30)
        let vargaCalc = VargaCalculator()
        let saptaVargas: [VargaType] = [.d1, .d2, .d3, .d7, .d9, .d12, .d30]
        var vargaCharts: [VargaType: VargaChart] = [:]
        for v in saptaVargas {
            vargaCharts[v] = vargaCalc.computeVarga(v, from: chart)
        }

        var results: [Planet: PlanetShadBala] = [:]

        for planet in Planet.signLords {
            guard let pos = chart.position(of: planet) else { continue }

            // 1. Sthana Bala
            let uchcha = uchchaBala(planet: planet, longitude: pos.longitude)
            let saptavargaja = saptavargajaBala(planet: planet, chart: chart, vargaCharts: vargaCharts)
            let ojha = ojhayugmarasiBala(planet: planet, longitude: pos.longitude)
            let kendra = kendradiBala(planet: planet, chart: chart)
            let drekkana = drekkanaBala(planet: planet, degreeInSign: pos.degreeInSign)

            // 2. Dig Bala
            let dig = digBala(planet: planet, chart: chart)

            // 3. Kala Bala (Naisargika is NOT included here — it's a separate component)
            let paksha = pakshaBala(planet: planet, chart: chart)
            let natonnatha = natonnathaBala(planet: planet, chart: chart)
            let tribhaga = tribhagaBala(planet: planet, chart: chart)
            let abda = abdaBala(planet: planet, chart: chart)
            let masa = masaBala(planet: planet, chart: chart)
            let vara = varaBala(planet: planet, chart: chart)
            let hora = horaBala(planet: planet, chart: chart)
            let ayana = ayanaBala(planet: planet, chart: chart)

            // 4. Cheshta Bala (Sun=Ayana, Moon=Paksha, others=Cheshta Kendra)
            let cheshta = cheshtaBala(planet: planet, chart: chart)

            // 5. Naisargika Bala (separate 6th component)
            let naisargika = naisargikaBala(planet: planet)

            // 6. Drik Bala
            let drik = drikBala(planet: planet, chart: chart)

            results[planet] = PlanetShadBala(
                planet: planet,
                uchchaBala: uchcha,
                saptavargajaBala: saptavargaja,
                ojhayugmarasiBala: ojha,
                kendradiBala: kendra,
                drekkanaBala: drekkana,
                digBala: dig,
                pakshaBala: paksha,
                natonnathaBala: natonnatha,
                tribhagaBala: tribhaga,
                abdaBala: abda,
                masaBala: masa,
                varaBala: vara,
                horaBala: hora,
                ayanaBala: ayana,
                cheshtaBala: cheshta,
                naisargikaBala: naisargika,
                drikBala: drik
            )
        }

        return ShadBalaResult(planetBala: results)
    }

    // MARK: - 1A. Uchcha Bala (Exaltation Strength) — 0 to 60 virupas

    private static let deepExaltation: [Planet: Double] = [
        .sun: 10.0, .moon: 33.0, .mars: 298.0, .mercury: 165.0,
        .jupiter: 95.0, .venus: 357.0, .saturn: 200.0
    ]

    private func uchchaBala(planet: Planet, longitude: Double) -> Double {
        guard let exaltDeg = Self.deepExaltation[planet] else { return 0 }
        let debilDeg = (exaltDeg + 180.0).truncatingRemainder(dividingBy: 360.0)
        var arc = abs(longitude - debilDeg)
        if arc > 180.0 { arc = 360.0 - arc }
        return arc / 3.0
    }

    // MARK: - 1B. Saptavargaja Bala — 7 vargas with compound friendship

    private func saptavargajaBala(
        planet: Planet, chart: BirthChart,
        vargaCharts: [VargaType: VargaChart]
    ) -> Double {
        guard let pos = chart.position(of: planet) else { return 0 }
        let saptaVargas: [VargaType] = [.d1, .d2, .d3, .d7, .d9, .d12, .d30]
        var total = 0.0

        for varga in saptaVargas {
            let sign: Sign
            if varga == .d1 {
                sign = pos.sign
            } else if let vc = vargaCharts[varga], let s = vc.sign(of: planet) {
                sign = s
            } else {
                continue
            }

            let isMT = varga == .d1 && PlanetaryFriendship.isMoolatrikona(planet: planet, longitude: pos.longitude)

            total += PlanetaryFriendship.saptavargajaPoints(
                planet: planet, inSign: sign, chart: chart, isMoolatrikona: isMT
            )
        }

        return total
    }

    // MARK: - 1C. Ojhayugmarasi Bala (Odd/Even) — 0 to 30 virupas

    private func ojhayugmarasiBala(planet: Planet, longitude: Double) -> Double {
        let sign = Sign.from(longitude: longitude)
        let navamsaSignIndex = VargaType.d9.vargaSignIndex(for: longitude)
        let navamsaSign = Sign(rawValue: navamsaSignIndex)!

        let prefersOdd: Bool
        switch planet {
        case .moon, .venus: prefersOdd = false
        default: prefersOdd = true
        }

        var total = 0.0
        if prefersOdd == sign.isOdd { total += 15.0 }
        if prefersOdd == navamsaSign.isOdd { total += 15.0 }
        return total
    }

    // MARK: - 1D. Kendradi Bala — 15, 30, or 60 virupas

    private func kendradiBala(planet: Planet, chart: BirthChart) -> Double {
        guard let house = chart.house(of: planet) else { return 0 }
        switch house {
        case 1, 4, 7, 10: return 60.0
        case 2, 5, 8, 11: return 30.0
        default:           return 15.0
        }
    }

    // MARK: - 1E. Drekkana Bala — 0 or 15 virupas

    private func drekkanaBala(planet: Planet, degreeInSign: Double) -> Double {
        let gender = planetGender(planet)
        let decanate: Int
        if degreeInSign < 10.0 { decanate = 1 }
        else if degreeInSign < 20.0 { decanate = 2 }
        else { decanate = 3 }

        switch (decanate, gender) {
        case (1, .male), (2, .neutral), (3, .female): return 15.0
        default: return 0.0
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

    // MARK: - 2. Dig Bala (Directional Strength) — 0 to 60 virupas
    // BPHS: degree-based using actual Asc/MC/IC/Desc longitudes, NOT whole-sign houses.
    // Subtract the powerless point longitude from the planet longitude.

    private func digBala(planet: Planet, chart: BirthChart) -> Double {
        guard let planetLong = chart.position(of: planet)?.longitude,
              let ascLong = chart.ascendant?.longitude,
              let mcLong = chart.mc else { return 0 }

        let descLong = (ascLong + 180.0).truncatingRemainder(dividingBy: 360.0)
        let icLong = (mcLong + 180.0).truncatingRemainder(dividingBy: 360.0)

        // Powerless point = cusp opposite to where planet is strongest
        let powerlessPoint: Double
        switch planet {
        case .sun, .mars:        powerlessPoint = icLong   // Strong at MC, weak at IC
        case .moon, .venus:      powerlessPoint = mcLong   // Strong at IC, weak at MC
        case .jupiter, .mercury: powerlessPoint = descLong // Strong at Asc, weak at Desc
        case .saturn:            powerlessPoint = ascLong  // Strong at Desc, weak at Asc
        default:                 return 0
        }

        var arc = abs(planetLong - powerlessPoint)
        if arc > 180.0 { arc = 360.0 - arc }
        return arc / 3.0
    }

    // MARK: - 3A. Paksha Bala (Lunar Phase)
    // Benefics get raw value (0-60), malefics get (60 - raw).
    // Moon's Paksha Bala is DOUBLED per BPHS (max 120 virupas).
    // Moon's Cheshta Bala reuses the RAW (non-doubled) Paksha via pakshaBalaRaw().

    private func pakshaBala(planet: Planet, chart: BirthChart) -> Double {
        guard let moonLong = chart.position(of: .moon)?.longitude,
              let sunLong = chart.position(of: .sun)?.longitude else { return 0 }

        var diff = moonLong - sunLong
        if diff < 0 { diff += 360.0 }

        let rawBala: Double
        if diff <= 180.0 {
            rawBala = diff / 3.0
        } else {
            rawBala = (360.0 - diff) / 3.0
        }

        let isBenefic: Bool
        switch planet {
        case .jupiter, .venus, .moon, .mercury: isBenefic = true
        default: isBenefic = false
        }

        let bala = isBenefic ? rawBala : (60.0 - rawBala)

        // BPHS: Moon's Paksha Bala is doubled (max 120 virupas)
        if planet == .moon { return bala * 2.0 }
        return bala
    }

    // MARK: - 3B. Natonnatha Bala (Day/Night Strength) — 0 to 60 virupas
    // Diurnal planets (Sun, Jupiter, Venus): max 60 at local noon, 0 at midnight.
    // Nocturnal planets (Moon, Mars, Saturn): max 60 at midnight, 0 at noon.
    // Mercury: always 60.
    // Simple linear interpolation between noon and midnight.

    private func natonnathaBala(planet: Planet, chart: BirthChart) -> Double {
        guard let sunrise = chart.sunrise, let sunset = chart.sunset else { return 0 }

        // Mercury always gets 60
        if planet == .mercury { return 60.0 }

        let isDiurnal: Bool
        switch planet {
        case .sun, .jupiter, .venus: isDiurnal = true
        case .moon, .mars, .saturn:  isDiurnal = false
        default: return 0
        }

        let birthTime = chart.birthData.dateTimeUTC.timeIntervalSince1970
        let sunriseTime = sunrise.timeIntervalSince1970
        let sunsetTime = sunset.timeIntervalSince1970

        // Calculate local apparent noon and midnight
        let noon = (sunriseTime + sunsetTime) / 2.0
        let midnight: Double
        if birthTime >= noon {
            midnight = sunsetTime + (86400.0 - (sunsetTime - sunriseTime)) / 2.0
        } else {
            midnight = sunriseTime - (86400.0 - (sunsetTime - sunriseTime)) / 2.0
        }

        // Distance from noon (0 = noon, ~0.5 day = midnight) normalized to 0-1
        let halfDay = abs(midnight - noon)  // ~12 hours in seconds
        let distFromNoon = abs(birthTime - noon)
        let ratio = min(distFromNoon / halfDay, 1.0)  // 0 at noon, 1 at midnight

        if isDiurnal {
            // Max at noon (ratio=0), min at midnight (ratio=1)
            return 60.0 * (1.0 - ratio)
        } else {
            // Max at midnight (ratio=1), min at noon (ratio=0)
            return 60.0 * ratio
        }
    }

    // MARK: - 3C. Tribhaga Bala — 0 or 60 virupas

    private func tribhagaBala(planet: Planet, chart: BirthChart) -> Double {
        // Jupiter always gets 60
        if planet == .jupiter { return 60.0 }

        guard let sunrise = chart.sunrise, let sunset = chart.sunset else { return 0 }
        let birthTime = chart.birthData.dateTimeUTC.timeIntervalSince1970
        let sunriseTime = sunrise.timeIntervalSince1970
        let sunsetTime = sunset.timeIntervalSince1970

        let isDayBirth = birthTime >= sunriseTime && birthTime <= sunsetTime

        if isDayBirth {
            let dayLength = sunsetTime - sunriseTime
            let elapsed = birthTime - sunriseTime
            let third = dayLength / 3.0
            let dayThird: Int
            if elapsed < third { dayThird = 1 }
            else if elapsed < third * 2.0 { dayThird = 2 }
            else { dayThird = 3 }

            // Day: 1st=Mercury, 2nd=Sun, 3rd=Saturn
            switch (dayThird, planet) {
            case (1, .mercury), (2, .sun), (3, .saturn): return 60.0
            default: return 0
            }
        } else {
            let nightLength: Double
            let elapsed: Double
            if birthTime > sunsetTime {
                nightLength = (sunriseTime + 86400.0) - sunsetTime
                elapsed = birthTime - sunsetTime
            } else {
                nightLength = sunriseTime - (sunsetTime - 86400.0)
                elapsed = birthTime - (sunsetTime - 86400.0)
            }
            let third = nightLength / 3.0
            let nightThird: Int
            if elapsed < third { nightThird = 1 }
            else if elapsed < third * 2.0 { nightThird = 2 }
            else { nightThird = 3 }

            // Night: 1st=Moon, 2nd=Venus, 3rd=Mars
            switch (nightThird, planet) {
            case (1, .moon), (2, .venus), (3, .mars): return 60.0
            default: return 0
            }
        }
    }

    // MARK: - 3D. Abda Bala (Year Lord) — 0 or 15 virupas
    // Per BPHS: Abda lord index = (yearNumber * 3 + 1) % 7

    private func abdaBala(planet: Planet, chart: BirthChart) -> Double {
        let yearLord = abdaLord(julianDay: chart.julianDay)
        return planet == yearLord ? 15.0 : 0
    }

    private func abdaLord(julianDay: Double) -> Planet {
        let kaliEpoch = 588465.5
        let daysSinceKali = julianDay - kaliEpoch
        let yearNumber = Int(daysSinceKali / 360.0)
        let index = ((yearNumber * 3 + 1) % 7 + 7) % 7
        return weekdayLord(index: index)
    }

    // MARK: - 3E. Masa Bala (Month Lord) — 0 or 30 virupas
    // Per BPHS: Masa lord index = (monthNumber * 2 + 1) % 7

    private func masaBala(planet: Planet, chart: BirthChart) -> Double {
        let monthLord = masaLord(julianDay: chart.julianDay)
        return planet == monthLord ? 30.0 : 0
    }

    private func masaLord(julianDay: Double) -> Planet {
        let kaliEpoch = 588465.5
        let daysSinceKali = julianDay - kaliEpoch
        let monthNumber = Int(daysSinceKali / 30.0)
        let index = ((monthNumber * 2 + 1) % 7 + 7) % 7
        return weekdayLord(index: index)
    }

    // MARK: - 3F. Vara Bala (Weekday Lord) — 0 or 45 virupas
    // Uses Vedic day (sunrise-based), not civil day (midnight-based).

    private func varaBala(planet: Planet, chart: BirthChart) -> Double {
        let varaLord = vedicWeekdayLord(chart: chart)
        return planet == varaLord ? 45.0 : 0
    }

    /// Vedic weekday lord: if birth is before sunrise, use previous day's lord.
    private func vedicWeekdayLord(chart: BirthChart) -> Planet {
        var weekday = Int(floor(chart.julianDay + 1.5).truncatingRemainder(dividingBy: 7))
        weekday = ((weekday % 7) + 7) % 7

        // Vedic day starts at sunrise — if birth is before sunrise, go back one day
        if let sunrise = chart.sunrise {
            if chart.birthData.dateTimeUTC < sunrise {
                weekday = (weekday - 1 + 7) % 7
            }
        }

        return jdWeekdayToPlanet(weekday)
    }

    /// Convert JD-based weekday index to planet lord.
    /// floor(JD + 1.5) % 7 gives: 0=Sunday, 1=Monday, 2=Tuesday, etc.
    private func jdWeekdayToPlanet(_ weekday: Int) -> Planet {
        switch weekday {
        case 0: return .sun      // Sunday
        case 1: return .moon     // Monday
        case 2: return .mars     // Tuesday
        case 3: return .mercury  // Wednesday
        case 4: return .jupiter  // Thursday
        case 5: return .venus    // Friday
        case 6: return .saturn   // Saturday
        default: return .sun
        }
    }

    // MARK: - 3G. Hora Bala (Planetary Hour Lord) — 0 or 60 virupas

    private func horaBala(planet: Planet, chart: BirthChart) -> Double {
        guard let sunrise = chart.sunrise, let sunset = chart.sunset else { return 0 }
        let birthTime = chart.birthData.dateTimeUTC.timeIntervalSince1970
        let sunriseTime = sunrise.timeIntervalSince1970
        let sunsetTime = sunset.timeIntervalSince1970

        let isDayBirth = birthTime >= sunriseTime && birthTime <= sunsetTime
        let varaLord = vedicWeekdayLord(chart: chart)

        // Chaldean order: Sun, Venus, Mercury, Moon, Saturn, Jupiter, Mars
        let chaldeanOrder: [Planet] = [.sun, .venus, .mercury, .moon, .saturn, .jupiter, .mars]
        guard let startIndex = chaldeanOrder.firstIndex(of: varaLord) else { return 0 }

        let horaNumber: Int
        if isDayBirth {
            let dayLength = sunsetTime - sunriseTime
            let horaLength = dayLength / 12.0
            let elapsed = birthTime - sunriseTime
            horaNumber = min(Int(elapsed / horaLength), 11)
        } else {
            let nightLength: Double
            let elapsed: Double
            if birthTime > sunsetTime {
                nightLength = (sunriseTime + 86400.0) - sunsetTime
                elapsed = birthTime - sunsetTime
            } else {
                nightLength = sunriseTime - (sunsetTime - 86400.0)
                elapsed = birthTime - (sunsetTime - 86400.0)
            }
            let horaLength = nightLength / 12.0
            horaNumber = 12 + min(Int(elapsed / horaLength), 11)
        }

        let lordIndex = (startIndex + horaNumber) % 7
        let horaLord = chaldeanOrder[lordIndex]
        return planet == horaLord ? 60.0 : 0
    }

    // MARK: - 3H. Ayana Bala (Declination Strength) — 0 to 60 virupas
    // Formula per BPHS/R. Santhanam: Ayana Bala = (24 + Kranti) × 1.2794
    // where Kranti = declination with appropriate sign per planet.

    private func ayanaBala(planet: Planet, chart: BirthChart) -> Double {
        guard let pos = chart.position(of: planet) else { return 0 }

        // Convert sidereal to tropical: tropical = sidereal + ayanamsa
        let tropicalLong = pos.longitude + chart.ayanamsaValue

        // Obliquity of the ecliptic (~23°27' = 23.45°)
        let obliquity = 23.45

        // Declination = arcsin(sin(tropical_longitude) * sin(obliquity))
        let tropRad = tropicalLong * .pi / 180.0
        let oblRad = obliquity * .pi / 180.0
        let declination = asin(sin(tropRad) * sin(oblRad)) * 180.0 / .pi

        // Determine effective Kranti based on planet preference
        let kranti: Double
        switch planet {
        case .sun, .mars, .jupiter, .venus:
            // Prefer northern declination: use declination as-is
            kranti = declination
        case .moon, .saturn:
            // Prefer southern declination: negate
            kranti = -declination
        case .mercury:
            // Mercury benefits from both: always positive
            kranti = abs(declination)
        default:
            return 0
        }

        // BPHS formula: (obliquity + Kranti) × (30 / obliquity)
        // This gives ~0 when Kranti = -obliquity and ~60 when Kranti = +obliquity
        var bala = (obliquity + kranti) * (30.0 / obliquity)
        bala = max(0, min(bala, 60.0))

        // BPHS: Sun's Ayana Bala is doubled
        if planet == .sun { bala *= 2.0 }
        return bala
    }

    // MARK: - 4. Cheshta Bala (Motional Strength) — 0 to 60 virupas
    // Sun: Cheshta Bala = Ayana Bala (reused — appears twice in total)
    // Moon: Cheshta Bala = Paksha Bala (reused — appears twice in total)
    // Others: Cheshta Kendra based on Surya Siddhanta mean longitudes.
    //   Superior planets: Cheshta Kendra = |Mean Sun - Mean Planet|
    //   Inferior planets: Cheshta Kendra = |Sheeghrochcha - Mean Sun|
    //     where Sheeghrochcha = planet's mean heliocentric longitude.

    // Surya Siddhanta revolutions per Mahayuga (4,320,000 years)
    private static let ssMahayugaDays: Double = 1_577_917_828
    private static let ssRevolutions: [Planet: Double] = [
        .sun: 4_320_000,         // Sun's own revolutions
        .mars: 2_296_832,        // Mars mean planet
        .jupiter: 364_220,       // Jupiter mean planet
        .saturn: 146_568,        // Saturn mean planet
        .mercury: 17_937_060,    // Mercury Sheeghrochcha (heliocentric)
        .venus: 7_022_376,       // Venus Sheeghrochcha (heliocentric)
    ]

    /// Surya Siddhanta mean longitude from Kali Yuga epoch.
    private func ssMeanLongitude(planet: Planet, julianDay: Double) -> Double {
        guard let revs = Self.ssRevolutions[planet] else { return 0 }
        let kaliEpoch = 588465.5
        let ahargana = julianDay - kaliEpoch
        var meanLong = (revs / Self.ssMahayugaDays) * ahargana * 360.0
        meanLong = meanLong.truncatingRemainder(dividingBy: 360.0)
        if meanLong < 0 { meanLong += 360.0 }
        return meanLong
    }

    private func cheshtaBala(planet: Planet, chart: BirthChart) -> Double {
        if planet == .sun {
            return ayanaBala(planet: .sun, chart: chart)
        }
        if planet == .moon {
            // Moon's Cheshta = Paksha Bala (non-doubled value)
            return pakshaBalaRaw(chart: chart)
        }

        guard let trueLong = chart.position(of: planet)?.longitude else { return 0 }
        let meanSun = ssMeanLongitude(planet: .sun, julianDay: chart.julianDay)

        let cheshtaKendra: Double
        switch planet {
        case .mars, .jupiter, .saturn:
            // Superior: Sheeghrochcha = Mean Sun
            // Average = (Mean Planet + True Planet) / 2
            let meanPlanet = ssMeanLongitude(planet: planet, julianDay: chart.julianDay)
            let avg = midpoint(meanPlanet, trueLong)
            var diff = abs(meanSun - avg)
            if diff > 180.0 { diff = 360.0 - diff }
            cheshtaKendra = diff

        case .mercury, .venus:
            // Inferior: Sheeghrochcha = planet's mean heliocentric longitude
            // Mean Planet = Mean Sun. Average = (Mean Sun + True Planet) / 2
            let sheeghrochcha = ssMeanLongitude(planet: planet, julianDay: chart.julianDay)
            let avg = midpoint(meanSun, trueLong)
            var diff = abs(sheeghrochcha - avg)
            if diff > 180.0 { diff = 360.0 - diff }
            cheshtaKendra = diff

        default:
            return 0
        }

        return min(cheshtaKendra / 3.0, 60.0)
    }

    /// Raw (non-doubled) Paksha Bala for Moon's Cheshta Bala reuse.
    private func pakshaBalaRaw(chart: BirthChart) -> Double {
        guard let moonLong = chart.position(of: .moon)?.longitude,
              let sunLong = chart.position(of: .sun)?.longitude else { return 0 }
        var diff = moonLong - sunLong
        if diff < 0 { diff += 360.0 }
        if diff <= 180.0 { return diff / 3.0 }
        return (360.0 - diff) / 3.0
    }

    /// Midpoint of two longitudes on the circle.
    private func midpoint(_ a: Double, _ b: Double) -> Double {
        var diff = b - a
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        var mid = a + diff / 2.0
        if mid < 0 { mid += 360 }
        if mid >= 360 { mid -= 360 }
        return mid
    }

    // MARK: - 5. Naisargika Bala (Natural Strength) — fixed values
    // Separate 6th component of Shadbala per BPHS, NOT part of Kala Bala.

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

    // MARK: - 6. Drik Bala (Aspectual Strength) — can be negative

    private func drikBala(planet: Planet, chart: BirthChart) -> Double {
        guard let targetLong = chart.position(of: planet)?.longitude else { return 0 }

        // Determine Moon's benefic/malefic status (waxing = benefic, waning = malefic)
        let moonIsBenefic: Bool
        if let moonLong = chart.position(of: .moon)?.longitude,
           let sunLong = chart.position(of: .sun)?.longitude {
            var moonSunDiff = moonLong - sunLong
            if moonSunDiff < 0 { moonSunDiff += 360.0 }
            moonIsBenefic = moonSunDiff <= 180.0
        } else {
            moonIsBenefic = true
        }

        var totalBenefic = 0.0
        var totalMalefic = 0.0

        for other in Planet.signLords where other != planet {
            guard let otherLong = chart.position(of: other)?.longitude else { continue }

            var dist = targetLong - otherLong
            if dist < 0 { dist += 360.0 }

            let drishtiValue = sphashtaDrishti(angularDistance: dist, aspectingPlanet: other)
            if drishtiValue <= 0 { continue }

            // BPHS: Jupiter and Mercury aspects are "superadded" (full value).
            // Other benefics/malefics contribute at 1/4 value.
            // Benefics = Venus, waxing Moon. Malefics = Sun, Mars, Saturn, waning Moon.
            switch other {
            case .jupiter, .mercury:
                // Superadded at full value as benefic
                totalBenefic += drishtiValue
            case .venus:
                totalBenefic += drishtiValue
            case .moon:
                if moonIsBenefic {
                    totalBenefic += drishtiValue
                } else {
                    totalMalefic += drishtiValue
                }
            default:  // Sun, Mars, Saturn
                totalMalefic += drishtiValue
            }
        }

        // BPHS: "Reduce one fourth ... Super add entire Drishti of Mercury and Jupiter"
        return (totalBenefic - totalMalefic) / 4.0
    }

    /// Sphashta Drishti (aspect strength) based on angular distance.
    private func sphashtaDrishti(angularDistance d: Double, aspectingPlanet: Planet) -> Double {
        var value = baseDrishti(d)

        // Special full-strength aspects
        switch aspectingPlanet {
        case .mars:
            if isNear(d, target: 90.0, orb: 15.0) {
                value = max(value, specialAspectStrength(d, target: 90.0))
            }
            if isNear(d, target: 210.0, orb: 15.0) {
                value = max(value, specialAspectStrength(d, target: 210.0))
            }
        case .jupiter:
            if isNear(d, target: 120.0, orb: 15.0) {
                value = max(value, specialAspectStrength(d, target: 120.0))
            }
            if isNear(d, target: 240.0, orb: 15.0) {
                value = max(value, specialAspectStrength(d, target: 240.0))
            }
        case .saturn:
            if isNear(d, target: 60.0, orb: 15.0) {
                value = max(value, specialAspectStrength(d, target: 60.0))
            }
            if isNear(d, target: 270.0, orb: 15.0) {
                value = max(value, specialAspectStrength(d, target: 270.0))
            }
        default: break
        }

        return max(0, value)
    }

    private func baseDrishti(_ d: Double) -> Double {
        if d < 30.0 || d > 300.0 { return 0 }
        if d >= 30.0 && d < 60.0 { return d / 2.0 - 15.0 }
        if d >= 60.0 && d < 90.0 { return d - 45.0 }
        if d >= 90.0 && d < 120.0 { return 90.0 - d / 2.0 }
        if d >= 120.0 && d < 150.0 { return d - 90.0 }
        if d >= 150.0 && d <= 180.0 { return 2.0 * d - 300.0 }
        if d > 180.0 && d <= 300.0 { return 150.0 - d / 2.0 }
        return 0
    }

    private func specialAspectStrength(_ d: Double, target: Double) -> Double {
        let diff = abs(d - target)
        if diff > 15.0 { return 0 }
        return 60.0 * (1.0 - diff / 15.0)
    }

    private func isNear(_ d: Double, target: Double, orb: Double) -> Bool {
        abs(d - target) <= orb
    }

    // MARK: - Helpers

    private func weekdayLord(index: Int) -> Planet {
        switch index {
        case 0: return .sun
        case 1: return .moon
        case 2: return .mars
        case 3: return .mercury
        case 4: return .jupiter
        case 5: return .venus
        case 6: return .saturn
        default: return .sun
        }
    }
}
