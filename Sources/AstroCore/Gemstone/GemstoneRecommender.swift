import Foundation

public struct GemstoneRecommender: Sendable {

    public init() {}

    public func recommend(
        chart: BirthChart,
        shadbala: ShadBalaResult?,
        ashtakavarga: AshtakavargaResult?,
        navamsa: VargaChart?,
        dashas: [DashaPeriod]?,
        karakas: CharaKarakaResult?,
        currentDate: Date = Date()
    ) -> GemstoneResult? {
        guard chart.lagnaSign != nil else { return nil }

        var scores: [PlanetGemstoneScore] = []

        // Score the 7 sign lords (Sun–Saturn)
        for planet in Planet.signLords {
            let score = scorePlanet(
                planet,
                chart: chart,
                shadbala: shadbala,
                ashtakavarga: ashtakavarga,
                navamsa: navamsa,
                dashas: dashas,
                currentDate: currentDate
            )
            scores.append(score)
        }

        // Score Rahu and Ketu (shadow planets — different scoring)
        for planet in [Planet.rahu, Planet.ketu] {
            let score = scoreShadowPlanet(
                planet,
                chart: chart,
                navamsa: navamsa,
                dashas: dashas,
                currentDate: currentDate
            )
            scores.append(score)
        }

        // Sort by: non-disqualified first, then by totalScore descending
        scores.sort { a, b in
            if a.isDisqualified != b.isDisqualified {
                return !a.isDisqualified
            }
            return a.totalScore > b.totalScore
        }

        guard let best = scores.first, !best.isDisqualified else { return nil }

        let gemstone = best.gemstone
        let reasoning = buildReasoning(best, chart: chart, dashas: dashas, currentDate: currentDate)
        let warnings = buildWarnings(best, chart: chart)

        // Confidence: based on margin over second-best
        let secondBest = scores.dropFirst().first(where: { !$0.isDisqualified })
        let margin = secondBest.map { best.totalScore - $0.totalScore } ?? best.totalScore
        let confidence = min(100, max(20, Int(40 + margin * 0.8)))

        return GemstoneResult(
            recommendedPlanet: best.planet,
            gemstone: gemstone,
            alternativeGemstone: gemstone.alternativeStones.first,
            confidence: confidence,
            reasoning: reasoning,
            warnings: warnings,
            allScores: scores,
            wearingInstructions: WearingInstructions(
                finger: gemstone.finger,
                metal: gemstone.metal,
                day: gemstone.day,
                mantra: gemstone.mantra
            )
        )
    }

    // MARK: - Per-Planet Scoring

    private func scorePlanet(
        _ planet: Planet,
        chart: BirthChart,
        shadbala: ShadBalaResult?,
        ashtakavarga: AshtakavargaResult?,
        navamsa: VargaChart?,
        dashas: [DashaPeriod]?,
        currentDate: Date
    ) -> PlanetGemstoneScore {
        let houses = housesOwned(by: planet, in: chart)
        let disqualification = checkDisqualification(planet: planet, houses: houses, chart: chart)

        // 1. Functional Beneficence (weight: 25%)
        let funcScore = functionalBeneficenceScore(planet: planet, houses: houses, chart: chart)

        // 2. Lagna Lord Bonus (weight: 15%)
        let lagnaScore = lagnaLordScore(planet: planet, chart: chart)

        // 3. ShadBala Strength (weight: 15%)
        let shadScore = shadBalaScore(planet: planet, shadbala: shadbala)

        // 4. Dasha Relevance (weight: 12%)
        let dashaScore = dashaRelevanceScore(planet: planet, dashas: dashas, currentDate: currentDate)

        // 5. D1 Dignity (weight: 10%)
        let d1Score = dignityScore(planet: planet, chart: chart, isNavamsa: false)

        // 6. D9 Dignity (weight: 10%)
        let d9Score = navamsaDignityScore(planet: planet, chart: chart, navamsa: navamsa)

        // 7. Ashtakavarga (weight: 8%)
        let ashtaScore = ashtakavargaScore(planet: planet, chart: chart, ashtakavarga: ashtakavarga)

        // 8. Yogakaraka (weight: 5%)
        let yogaScore = yogakarakaScore(planet: planet, houses: houses)

        // Weighted total
        var total = funcScore * 0.25
            + lagnaScore * 0.15
            + shadScore * 0.15
            + dashaScore * 0.12
            + d1Score * 0.10
            + d9Score * 0.10
            + ashtaScore * 0.08
            + yogaScore * 0.05

        // Soft adjustments
        total += softAdjustments(planet: planet, chart: chart, funcScore: funcScore)

        let breakdown = GemstoneScoreBreakdown(
            functionalBeneficence: funcScore,
            lagnaLordBonus: lagnaScore,
            shadBalaStrength: shadScore,
            dashaRelevance: dashaScore,
            d1Dignity: d1Score,
            d9Dignity: d9Score,
            ashtakavargaSupport: ashtaScore,
            yogakarakaBonus: yogaScore
        )

        let status = functionalStatus(funcScore: funcScore, lagnaScore: lagnaScore, yogaScore: yogaScore)

        return PlanetGemstoneScore(
            planet: planet,
            gemstone: Gemstone.forPlanet(planet)!,
            totalScore: max(0, total),
            breakdown: breakdown,
            functionalStatus: status,
            isDisqualified: disqualification != nil,
            disqualifyReason: disqualification
        )
    }

    // MARK: - Shadow Planet Scoring (Rahu & Ketu)

    private func scoreShadowPlanet(
        _ planet: Planet,
        chart: BirthChart,
        navamsa: VargaChart?,
        dashas: [DashaPeriod]?,
        currentDate: Date
    ) -> PlanetGemstoneScore {
        // Rahu/Ketu don't own houses, have no ShadBala or BAV.
        // Scoring: house placement (30%), dasha relevance (30%), D1 dignity (15%), D9 dignity (15%), dispositor strength (10%)

        // 1. House placement quality (weight: 30%)
        let housePlacement = shadowHousePlacementScore(planet: planet, chart: chart)

        // 2. Dasha relevance (weight: 30%) — very important for nodes
        let dashaScore = dashaRelevanceScore(planet: planet, dashas: dashas, currentDate: currentDate)

        // 3. D1 Dignity (weight: 15%) — Rahu exalted in Taurus/Gemini, Ketu in Scorpio/Sagittarius
        let d1Score = shadowDignityScore(planet: planet, chart: chart)

        // 4. D9 Dignity (weight: 15%)
        let d9Score = shadowNavamsaDignityScore(planet: planet, chart: chart, navamsa: navamsa)

        // 5. Dispositor strength (weight: 10%) — how strong is the sign lord where Rahu/Ketu sits
        let dispositorScore = dispositorStrengthScore(planet: planet, chart: chart)

        var total = housePlacement * 0.30
            + dashaScore * 0.30
            + d1Score * 0.15
            + d9Score * 0.15
            + dispositorScore * 0.10

        total = max(0, total)

        let breakdown = GemstoneScoreBreakdown(
            functionalBeneficence: housePlacement,
            lagnaLordBonus: 0,
            shadBalaStrength: dispositorScore,
            dashaRelevance: dashaScore,
            d1Dignity: d1Score,
            d9Dignity: d9Score,
            ashtakavargaSupport: 0,
            yogakarakaBonus: 0
        )

        // Rahu/Ketu functional status based on house placement
        let status: FunctionalStatus
        if housePlacement >= 60 { status = .benefic }
        else if housePlacement >= 35 { status = .neutral }
        else { status = .malefic }

        return PlanetGemstoneScore(
            planet: planet,
            gemstone: Gemstone.forPlanet(planet)!,
            totalScore: total,
            breakdown: breakdown,
            functionalStatus: status,
            isDisqualified: false,
            disqualifyReason: nil
        )
    }

    /// Score based on which house Rahu/Ketu occupies
    private func shadowHousePlacementScore(planet: Planet, chart: BirthChart) -> Double {
        guard let house = chart.house(of: planet) else { return 30 }
        // Favorable houses for nodes
        let trikonas: Set<Int> = [1, 5, 9]
        let kendras: Set<Int> = [4, 7, 10]  // H1 already in trikonas
        let upachaya: Set<Int> = [3, 6, 10, 11]  // Rahu/Ketu do well in upachaya
        let dusthanas: Set<Int> = [8, 12]  // 6 is upachaya, so only 8/12 are bad

        var score: Double = 40  // baseline
        if trikonas.contains(house) { score = 75 }
        else if kendras.contains(house) { score = 65 }
        else if upachaya.contains(house) { score = 60 }
        else if dusthanas.contains(house) { score = 20 }
        else { score = 35 }  // 2nd house etc.

        return score
    }

    /// Rahu: exalted in Taurus (some say Gemini), debilitated in Scorpio (some say Sagittarius)
    /// Ketu: exalted in Scorpio (some say Sagittarius), debilitated in Taurus (some say Gemini)
    private func shadowDignityScore(planet: Planet, chart: BirthChart) -> Double {
        guard let pos = chart.position(of: planet) else { return 40 }
        let sign = pos.sign

        if planet == .rahu {
            if sign == .taurus || sign == .gemini { return 75 }  // exalted
            if sign == .scorpio || sign == .sagittarius { return 15 }  // debilitated
        } else {  // ketu
            if sign == .scorpio || sign == .sagittarius { return 75 }  // exalted
            if sign == .taurus || sign == .gemini { return 15 }  // debilitated
        }

        // Friendly/neutral signs — based on dispositor's natural friendship with node's co-lord
        // Rahu acts like Saturn, Ketu acts like Mars
        let actingLike: Planet = planet == .rahu ? .saturn : .mars
        let friendship = PlanetaryFriendship.naturalFriendship(of: actingLike, with: sign.lord)
        switch friendship {
        case .adhiMitra: return 65
        case .mitra: return 55
        case .sama: return 40
        case .shatru: return 25
        case .adhiShatru: return 15
        }
    }

    private func shadowNavamsaDignityScore(planet: Planet, chart: BirthChart, navamsa: VargaChart?) -> Double {
        guard let navamsa = navamsa,
              let d9Sign = navamsa.sign(of: planet) else { return 40 }

        var score: Double
        if planet == .rahu {
            if d9Sign == .taurus || d9Sign == .gemini { score = 75 }
            else if d9Sign == .scorpio || d9Sign == .sagittarius { score = 15 }
            else {
                let friendship = PlanetaryFriendship.naturalFriendship(of: .saturn, with: d9Sign.lord)
                switch friendship {
                case .adhiMitra: score = 65
                case .mitra: score = 55
                case .sama: score = 40
                case .shatru: score = 25
                case .adhiShatru: score = 15
                }
            }
        } else {
            if d9Sign == .scorpio || d9Sign == .sagittarius { score = 75 }
            else if d9Sign == .taurus || d9Sign == .gemini { score = 15 }
            else {
                let friendship = PlanetaryFriendship.naturalFriendship(of: .mars, with: d9Sign.lord)
                switch friendship {
                case .adhiMitra: score = 65
                case .mitra: score = 55
                case .sama: score = 40
                case .shatru: score = 25
                case .adhiShatru: score = 15
                }
            }
        }

        // Vargottama bonus
        if let d1Sign = chart.position(of: planet)?.sign, d1Sign == d9Sign {
            score += 15
        }

        return min(100, score)
    }

    /// How strong is the dispositor (sign lord) of the shadow planet
    private func dispositorStrengthScore(planet: Planet, chart: BirthChart) -> Double {
        guard let pos = chart.position(of: planet) else { return 40 }
        let dispositor = pos.sign.lord

        // Check dispositor's house placement
        guard let dispHouse = chart.house(of: dispositor) else { return 40 }
        let trikonas: Set<Int> = [1, 5, 9]
        let kendras: Set<Int> = [1, 4, 7, 10]

        if trikonas.contains(dispHouse) { return 80 }
        if kendras.contains(dispHouse) { return 70 }
        return 40
    }

    // MARK: - House Ownership

    private func housesOwned(by planet: Planet, in chart: BirthChart) -> [Int] {
        var houses: [Int] = []
        for h in 1...12 {
            if chart.lordOf(house: h) == planet {
                houses.append(h)
            }
        }
        return houses
    }

    // MARK: - Disqualification

    private func checkDisqualification(planet: Planet, houses: [Int], chart: BirthChart) -> String? {
        let dusthanas: Set<Int> = [6, 8, 12]
        let trikonas: Set<Int> = [1, 5, 9]
        let kendras: Set<Int> = [1, 4, 7, 10]
        let marakas: Set<Int> = [2, 7]

        let houseSet = Set(houses)

        // Pure dusthana lord: owns only 6/8/12, no kendra or trikona
        if !houseSet.isEmpty &&
            houseSet.isSubset(of: dusthanas) &&
            houseSet.isDisjoint(with: trikonas) &&
            houseSet.isDisjoint(with: kendras) {
            return "Lords only dusthana houses (\(houses.sorted().map { "H\($0)" }.joined(separator: ", ")))"
        }

        // Pure maraka: owns only 2 and 7, no trikona
        if houseSet == marakas && houseSet.isDisjoint(with: trikonas) {
            return "Pure maraka lord (2L+7L) without trikona ownership"
        }

        return nil
    }

    // MARK: - Dimension 1: Functional Beneficence

    private func functionalBeneficenceScore(planet: Planet, houses: [Int], chart: BirthChart) -> Double {
        let trikonas: Set<Int> = [1, 5, 9]
        let kendras: Set<Int> = [1, 4, 7, 10]
        let dusthanas: Set<Int> = [6, 8, 12]
        let marakas: Set<Int> = [2, 7]

        var score: Double = 0

        for h in houses {
            if trikonas.contains(h) {
                score += 40
            }
            if kendras.contains(h) {
                // Kendradhipati dosha: natural benefics get reduced score for kendra lordship
                if planet.isNaturalBenefic {
                    score += 15
                } else {
                    score += 25
                }
            }
            if dusthanas.contains(h) {
                score -= 30
            }
            if marakas.contains(h) {
                score -= 15
            }
        }

        return min(100, max(0, score))
    }

    // MARK: - Dimension 2: Lagna Lord

    private func lagnaLordScore(planet: Planet, chart: BirthChart) -> Double {
        guard let lagnaLord = chart.lordOf(house: 1) else { return 0 }
        return planet == lagnaLord ? 100 : 0
    }

    // MARK: - Dimension 3: ShadBala Strength (Inverted-U)

    private func shadBalaScore(planet: Planet, shadbala: ShadBalaResult?) -> Double {
        guard let shadbala = shadbala,
              let bala = shadbala.planetBala[planet] else { return 50 }

        guard let minRupas = ShadBalaResult.minimumRupas[planet], minRupas > 0 else { return 50 }
        let ratio = bala.totalRupas / minRupas * 100.0

        if ratio < 50 { return 50 }
        if ratio <= 80 { return 80 }
        if ratio <= 120 { return 100 }
        if ratio <= 150 { return 70 }
        return 40  // >150%: overly strong, doesn't need gem support
    }

    // MARK: - Dimension 4: Dasha Relevance

    private func dashaRelevanceScore(planet: Planet, dashas: [DashaPeriod]?, currentDate: Date) -> Double {
        guard let dashas = dashas else { return 20 }

        let calc = VimshottariCalculator()
        let path = calc.activeDashaPath(in: dashas, at: currentDate)

        // Current Maha Dasha lord
        if let maha = path.first, maha.planet == planet { return 100 }

        // Current Antar Dasha lord
        if path.count > 1, path[1].planet == planet { return 70 }

        // Upcoming Maha Dasha within 5 years
        let fiveYears = currentDate.addingTimeInterval(5 * 365.25 * 86400)
        for dasha in dashas {
            if dasha.planet == planet &&
                dasha.startDate > currentDate &&
                dasha.startDate < fiveYears {
                return 50
            }
        }

        return 20
    }

    // MARK: - Dimension 5: D1 Dignity

    private func dignityScore(planet: Planet, chart: BirthChart, isNavamsa: Bool) -> Double {
        guard let pos = chart.position(of: planet) else { return 40 }
        let sign = pos.sign

        // Moolatrikona check
        if PlanetaryFriendship.isMoolatrikona(planet: planet, longitude: pos.longitude) {
            return 90
        }

        // Own sign
        if sign.lord == planet { return 80 }

        // Exalted (lower because planet may not need help)
        if Sign.exaltationSign(of: planet) == sign { return 70 }

        // Debilitated
        if Sign.debilitationSign(of: planet) == sign { return 5 }

        // Compound friendship-based dignity
        let friendship = PlanetaryFriendship.compoundFriendship(of: planet, with: sign.lord, chart: chart)
        switch friendship {
        case .adhiMitra: return 65
        case .mitra: return 55
        case .sama: return 40
        case .shatru: return 20
        case .adhiShatru: return 10
        }
    }

    // MARK: - Dimension 6: D9 Dignity

    private func navamsaDignityScore(planet: Planet, chart: BirthChart, navamsa: VargaChart?) -> Double {
        guard let navamsa = navamsa,
              let d9Sign = navamsa.sign(of: planet) else { return 40 }

        var score: Double

        // Own sign in D9
        if d9Sign.lord == planet {
            score = 80
        } else if Sign.exaltationSign(of: planet) == d9Sign {
            score = 70
        } else if Sign.debilitationSign(of: planet) == d9Sign {
            score = 5
        } else {
            // Use natural friendship for D9 since we don't have compound friendship there
            let friendship = PlanetaryFriendship.naturalFriendship(of: planet, with: d9Sign.lord)
            switch friendship {
            case .adhiMitra: score = 65
            case .mitra: score = 55
            case .sama: score = 40
            case .shatru: score = 20
            case .adhiShatru: score = 10
            }
        }

        // Vargottama bonus: same sign in D1 and D9
        if let d1Sign = chart.position(of: planet)?.sign, d1Sign == d9Sign {
            score += 15
        }

        return min(100, score)
    }

    // MARK: - Dimension 7: Ashtakavarga

    private func ashtakavargaScore(planet: Planet, chart: BirthChart, ashtakavarga: AshtakavargaResult?) -> Double {
        guard let ashtakavarga = ashtakavarga,
              let bav = ashtakavarga.bpiBindus[planet],
              let pos = chart.position(of: planet) else { return 50 }

        let bindus = bav.bindus(in: pos.sign)
        return Double(bindus) / 8.0 * 100.0
    }

    // MARK: - Dimension 8: Yogakaraka

    private func yogakarakaScore(planet: Planet, houses: [Int]) -> Double {
        // BPHS Yogakaraka: must own at least one pure kendra {4,7,10}
        // AND at least one pure trikona {5,9}.
        // H1 is excluded — it's both kendra and trikona, so owning it alone
        // doesn't satisfy the "owns both" requirement.
        let pureKendras: Set<Int> = [4, 7, 10]
        let pureTrikonas: Set<Int> = [5, 9]
        let houseSet = Set(houses)

        let ownsPureKendra = !houseSet.isDisjoint(with: pureKendras)
        let ownsPureTrikona = !houseSet.isDisjoint(with: pureTrikonas)

        return (ownsPureKendra && ownsPureTrikona) ? 100 : 0
    }

    // MARK: - Soft Adjustments

    private func softAdjustments(planet: Planet, chart: BirthChart, funcScore: Double) -> Double {
        var adjustment: Double = 0

        guard let pos = chart.position(of: planet) else { return 0 }

        // Combustion: if combust AND functional benefic, needs help → +5
        if planet != .sun {
            if let sunPos = chart.position(of: .sun) {
                let diff = abs(pos.longitude - sunPos.longitude)
                let angle = min(diff, 360 - diff)
                let combustThreshold: Double
                switch planet {
                case .moon: combustThreshold = 12
                case .mars: combustThreshold = 17
                case .mercury: combustThreshold = 14
                case .jupiter: combustThreshold = 11
                case .venus: combustThreshold = 10
                case .saturn: combustThreshold = 15
                default: combustThreshold = 0
                }
                if angle < combustThreshold && funcScore > 50 {
                    adjustment += 5
                }
            }
        }

        // Waning Moon + functional malefic → -10
        if planet == .moon {
            if let sunPos = chart.position(of: .sun) {
                let moonLon = pos.longitude
                let sunLon = sunPos.longitude
                let diff = (moonLon - sunLon + 360).truncatingRemainder(dividingBy: 360)
                let isWaning = diff > 180
                if isWaning && funcScore < 40 {
                    adjustment -= 10
                }
            }
        }

        // Neecha Bhanga: debilitated but lord of debilitation sign in kendra → +10
        if Sign.debilitationSign(of: planet) == pos.sign {
            let debSignLord = pos.sign.lord
            if let _ = chart.position(of: debSignLord),
               let lordHouse = chart.house(of: debSignLord) {
                let kendras: Set<Int> = [1, 4, 7, 10]
                if kendras.contains(lordHouse) {
                    adjustment += 10
                }
            }
        }

        return adjustment
    }

    // MARK: - Functional Status

    private func functionalStatus(funcScore: Double, lagnaScore: Double, yogaScore: Double) -> FunctionalStatus {
        if yogaScore == 100 || (funcScore >= 70 && lagnaScore == 100) { return .strongBenefic }
        if funcScore >= 50 || lagnaScore == 100 { return .benefic }
        if funcScore >= 30 { return .neutral }
        if funcScore >= 10 { return .malefic }
        return .strongMalefic
    }

    // MARK: - Reasoning

    private func buildReasoning(_ score: PlanetGemstoneScore, chart: BirthChart, dashas: [DashaPeriod]?, currentDate: Date) -> [String] {
        var reasons: [String] = []
        let planet = score.planet

        if planet == .rahu || planet == .ketu {
            if let house = chart.house(of: planet) {
                reasons.append("\(planet.rawValue) placed in H\(house) from \(chart.lagnaSign?.name ?? "Lagna")")
            }
            if let pos = chart.position(of: planet) {
                reasons.append("Dispositor: \(pos.sign.lord.rawValue) (lord of \(pos.sign.name))")
            }
        } else {
            let houses = housesOwned(by: planet, in: chart)
            let houseStr = houses.map { "H\($0)" }.joined(separator: ", ")
            reasons.append("\(planet.rawValue) owns \(houseStr) from \(chart.lagnaSign?.name ?? "Lagna")")
        }

        if score.breakdown.lagnaLordBonus == 100 {
            reasons.append("\(planet.rawValue) is the Lagna lord")
        }

        if score.breakdown.yogakarakaBonus == 100 {
            reasons.append("\(planet.rawValue) is a Yogakaraka (owns both kendra and trikona)")
        }

        switch score.functionalStatus {
        case .strongBenefic: reasons.append("Strong functional benefic for this lagna")
        case .benefic: reasons.append("Functional benefic for this lagna")
        default: break
        }

        if score.breakdown.dashaRelevance >= 70 {
            if let dashas = dashas {
                let path = VimshottariCalculator().activeDashaPath(in: dashas, at: currentDate)
                if let maha = path.first, maha.planet == planet {
                    reasons.append("Currently running \(planet.rawValue) Maha Dasha")
                } else if path.count > 1, path[1].planet == planet {
                    reasons.append("Currently running \(planet.rawValue) Antar Dasha")
                }
            }
        }

        if score.breakdown.shadBalaStrength >= 80 {
            reasons.append("Good ShadBala strength (moderately strong)")
        }

        return reasons
    }

    // MARK: - Warnings

    private func buildWarnings(_ score: PlanetGemstoneScore, chart: BirthChart) -> [String] {
        var warnings: [String] = []
        let planet = score.planet

        if let pos = chart.position(of: planet) {
            if Sign.debilitationSign(of: planet) == pos.sign {
                warnings.append("\(planet.rawValue) is debilitated in \(pos.sign.name) - gemstone may help strengthen it")
            }
            if pos.isRetrograde {
                warnings.append("\(planet.rawValue) is retrograde - effects may manifest differently")
            }
        }

        if score.breakdown.shadBalaStrength <= 50 {
            warnings.append("\(planet.rawValue) has low ShadBala strength")
        }

        return warnings
    }
}
