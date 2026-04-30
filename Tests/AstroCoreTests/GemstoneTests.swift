import Testing
import Foundation
@testable import AstroCore

@Suite("Gemstone Recommendation Tests", .serialized)
struct GemstoneTests {

    // MARK: - Helper

    private func computeChart(name: String, year: Int, month: Int, day: Int,
                               hour: Int, minute: Int, second: Int,
                               timeZoneID: String, lat: Double, lon: Double
    ) async -> (BirthChart, ShadBalaResult?, AshtakavargaResult?, VargaChart?, [DashaPeriod]?, CharaKarakaResult?) {
        let birthData = BirthData.from(
            name: name, year: year, month: month, day: day,
            hour: hour, minute: minute, second: second,
            timeZoneID: timeZoneID,
            latitude: lat, longitude: lon
        )

        await TestEphemeris.initialize()
        let calc = ChartCalculator(ephemeris: TestEphemeris.shared)
        let chart = await calc.computeChart(for: birthData)

        let shadbala = ShadBalaCalculator().compute(from: chart)
        let ashtakavarga = AshtakavargaCalculator().compute(from: chart)
        let allVargas = VargaCalculator().computeAllVargas(from: chart)
        let navamsa = allVargas[.d9]
        let dashas = VimshottariCalculator().computeDashas(from: chart)
        let karakas = CharaKarakaCalculator().compute(from: chart, useEightKaraka: false)

        return (chart, shadbala, ashtakavarga, navamsa, dashas, karakas)
    }

    /// Swoven's chart — known to produce Gemini lagna
    private func swovenChart() async -> (BirthChart, ShadBalaResult?, AshtakavargaResult?, VargaChart?, [DashaPeriod]?, CharaKarakaResult?) {
        return await computeChart(
            name: "Swoven", year: 1985, month: 9, day: 10,
            hour: 0, minute: 45, second: 0,
            timeZoneID: "Asia/Kathmandu", lat: 27.7172, lon: 85.3240
        )
    }

    // MARK: - Gemstone Enum Tests

    @Test("Gemstone-planet mapping is correct")
    func gemstoneForPlanet() {
        #expect(Gemstone.forPlanet(.sun) == .ruby)
        #expect(Gemstone.forPlanet(.moon) == .pearl)
        #expect(Gemstone.forPlanet(.mars) == .redCoral)
        #expect(Gemstone.forPlanet(.mercury) == .emerald)
        #expect(Gemstone.forPlanet(.jupiter) == .yellowSapphire)
        #expect(Gemstone.forPlanet(.venus) == .diamond)
        #expect(Gemstone.forPlanet(.saturn) == .blueSapphire)
        #expect(Gemstone.forPlanet(.rahu) == .hessonite)
        #expect(Gemstone.forPlanet(.ketu) == .catsEye)
    }

    @Test("All gemstones have names and properties")
    func gemstoneProperties() {
        for gem in Gemstone.allCases {
            #expect(!gem.name.isEmpty)
            #expect(!gem.sanskritName.isEmpty)
            #expect(!gem.metal.isEmpty)
            #expect(!gem.finger.isEmpty)
            #expect(!gem.day.isEmpty)
            #expect(!gem.mantra.isEmpty)
            #expect(!gem.alternativeStones.isEmpty)
        }
    }

    // MARK: - Recommendation Tests

    @Test("Recommendation returns a result for a valid chart")
    func basicRecommendation() async {
        let (chart, shadbala, ashtakavarga, navamsa, dashas, karakas) = await swovenChart()

        let recommender = GemstoneRecommender()
        let result = recommender.recommend(
            chart: chart, shadbala: shadbala, ashtakavarga: ashtakavarga,
            navamsa: navamsa, dashas: dashas, karakas: karakas
        )

        #expect(result != nil, "Should produce a recommendation")
        if let result = result {
            #expect(result.confidence >= 20 && result.confidence <= 100)
            #expect(!result.reasoning.isEmpty)
            #expect(result.allScores.count == 9, "Should score all 9 planets")
            #expect(!result.wearingInstructions.finger.isEmpty)
        }
    }

    @Test("Gemini lagna (Swoven): Mercury (1L+4L) or Venus (5L) should score high")
    func geminiLagnaScores() async {
        let (chart, shadbala, ashtakavarga, navamsa, dashas, karakas) = await swovenChart()
        guard let lagna = chart.lagnaSign else {
            Issue.record("No lagna")
            return
        }

        let recommender = GemstoneRecommender()
        let result = recommender.recommend(
            chart: chart, shadbala: shadbala, ashtakavarga: ashtakavarga,
            navamsa: navamsa, dashas: dashas, karakas: karakas
        )

        guard let result = result else {
            Issue.record("Expected recommendation")
            return
        }

        // For Gemini lagna: Mercury is 1L+4L, Venus is 5L
        let mercuryScore = result.allScores.first(where: { $0.planet == .mercury })
        #expect(mercuryScore != nil)
        if let ms = mercuryScore {
            #expect(!ms.isDisqualified, "Mercury should not be disqualified for Gemini lagna")
            #expect(ms.breakdown.lagnaLordBonus == 100, "Mercury should be lagna lord for Gemini")
        }
    }

    @Test("Yogakaraka detection: Saturn for Taurus lagna")
    func yogakarakaDetection() async {
        // Use a time that gives Taurus lagna for Delhi
        let (chart, shadbala, ashtakavarga, navamsa, dashas, karakas) = await computeChart(
            name: "Taurus Test", year: 1990, month: 4, day: 15,
            hour: 7, minute: 30, second: 0,
            timeZoneID: "Asia/Kolkata", lat: 28.6139, lon: 77.2090
        )

        guard let lagna = chart.lagnaSign else { return }

        let recommender = GemstoneRecommender()
        let result = recommender.recommend(
            chart: chart, shadbala: shadbala, ashtakavarga: ashtakavarga,
            navamsa: navamsa, dashas: dashas, karakas: karakas
        )

        guard let result = result else {
            Issue.record("Expected recommendation for \(lagna.name) lagna")
            return
        }

        // If Taurus lagna, Saturn should be yogakaraka (9L+10L)
        if lagna == .taurus {
            let satScore = result.allScores.first(where: { $0.planet == .saturn })
            #expect(satScore != nil)
            if let ss = satScore {
                #expect(ss.breakdown.yogakarakaBonus == 100, "Saturn should be yogakaraka for Taurus")
            }
        }
    }

    @Test("Disqualification: pure dusthana lords are disqualified")
    func disqualificationTest() async {
        let (chart, shadbala, ashtakavarga, navamsa, dashas, karakas) = await swovenChart()

        let recommender = GemstoneRecommender()
        let result = recommender.recommend(
            chart: chart, shadbala: shadbala, ashtakavarga: ashtakavarga,
            navamsa: navamsa, dashas: dashas, karakas: karakas
        )

        guard let result = result else { return }

        for score in result.allScores {
            if score.isDisqualified {
                #expect(score.disqualifyReason != nil, "Disqualified planet should have reason")
            }
        }

        // The recommended planet should never be disqualified
        #expect(!result.allScores[0].isDisqualified, "Top-ranked planet should not be disqualified")
    }

    @Test("All scores sorted correctly: non-DQ first, then by score descending")
    func scoresSorted() async {
        let (chart, shadbala, ashtakavarga, navamsa, dashas, karakas) = await swovenChart()

        let recommender = GemstoneRecommender()
        let result = recommender.recommend(
            chart: chart, shadbala: shadbala, ashtakavarga: ashtakavarga,
            navamsa: navamsa, dashas: dashas, karakas: karakas
        )

        guard let result = result else { return }

        var seenDisqualified = false
        for score in result.allScores {
            if score.isDisqualified {
                seenDisqualified = true
            } else {
                #expect(!seenDisqualified, "Non-DQ score should come before all DQ scores")
            }
        }

        let nonDQ = result.allScores.filter { !$0.isDisqualified }
        for i in 1..<nonDQ.count {
            #expect(nonDQ[i-1].totalScore >= nonDQ[i].totalScore,
                    "Scores should be descending")
        }
    }

    @Test("GemstoneResult is Codable")
    func codableResult() async {
        let (chart, shadbala, ashtakavarga, navamsa, dashas, karakas) = await swovenChart()

        let recommender = GemstoneRecommender()
        guard let result = recommender.recommend(
            chart: chart, shadbala: shadbala, ashtakavarga: ashtakavarga,
            navamsa: navamsa, dashas: dashas, karakas: karakas
        ) else { return }

        let encoder = JSONEncoder()
        let data = try? encoder.encode(result)
        #expect(data != nil, "GemstoneResult should encode to JSON")

        if let data = data {
            let decoder = JSONDecoder()
            let decoded = try? decoder.decode(GemstoneResult.self, from: data)
            #expect(decoded != nil, "GemstoneResult should decode from JSON")
            #expect(decoded?.gemstone == result.gemstone)
            #expect(decoded?.recommendedPlanet == result.recommendedPlanet)
        }
    }
}
