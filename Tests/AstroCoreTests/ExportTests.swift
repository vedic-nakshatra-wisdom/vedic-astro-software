import Testing
@testable import AstroCore
import Foundation

@Suite("Chart Export", .serialized)
struct ExportTests {

    private func eph() async -> EphemerisActor {
        await TestEphemeris.initialize()
        return TestEphemeris.shared
    }

    private func swovenChart() async -> BirthChart {
        let birthData = BirthData.from(
            name: "Swoven Pokharel",
            year: 1985, month: 9, day: 10,
            hour: 0, minute: 45, second: 0,
            timeZoneID: "Asia/Kathmandu",
            latitude: 27.7172, longitude: 85.3240
        )
        let calc = ChartCalculator(ephemeris: await eph())
        return await calc.computeChart(for: birthData)
    }

    // MARK: - ChartExport building

    @Test("Build export with all components")
    func buildExport() async throws {
        let chart = await swovenChart()
        let vargaCalc = VargaCalculator()
        let vargas = VargaType.allCases.map { vargaCalc.computeVarga($0, from: chart) }
        let dashaCalc = VimshottariCalculator()
        let dashas = dashaCalc.computeDashas(from: chart)

        let exporter = ChartExporter()
        let export = exporter.buildExport(
            chart: chart,
            vargas: vargas,
            dashas: dashas
        )

        #expect(export.divisionalCharts.count == 16)
        #expect(export.vimshottariDasha?.mahaDashas.count == 9)
        #expect(export.vimshottariDasha?.currentDasha != nil)
        #expect(export.metadata.engineVersion == "0.5")
        #expect(export.metadata.ayanamsa == "Lahiri")
    }

    @Test("Divisional charts are sorted by division number")
    func vargasSorted() async throws {
        let chart = await swovenChart()
        let vargaCalc = VargaCalculator()
        let vargas = VargaType.allCases.map { vargaCalc.computeVarga($0, from: chart) }

        let exporter = ChartExporter()
        let export = exporter.buildExport(chart: chart, vargas: vargas)

        let divisions = export.divisionalCharts.map { $0.division }
        #expect(divisions == [1, 2, 3, 4, 7, 9, 10, 12, 16, 20, 24, 27, 30, 40, 45, 60])
    }

    // MARK: - VargaExport

    @Test("VargaExport has ordered planet placements")
    func vargaExportStructure() async throws {
        let chart = await swovenChart()
        let vargaCalc = VargaCalculator()
        let d9 = vargaCalc.computeVarga(.d9, from: chart)
        let export = VargaExport(from: d9)

        #expect(export.name == "Navamsa")
        #expect(export.shortName == "D9")
        #expect(export.division == 9)
        #expect(export.placements.count == 9)
        #expect(export.placements[0].planet == "Sun")
        #expect(export.ascendantSign != nil)

        let data = try JSONEncoder().encode(export)
        #expect(data.count > 0)
    }

    // MARK: - JSON Export

    @Test("JSON export produces valid parseable JSON")
    func jsonExport() async throws {
        let chart = await swovenChart()
        let exporter = ChartExporter()
        let export = exporter.buildExport(chart: chart)

        let json = try exporter.toJSON(export)
        #expect(json.contains("Swoven Pokharel"))
        #expect(json.contains("Lahiri"))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChartExport.self, from: json.data(using: .utf8)!)
        #expect(decoded.birthData.name == "Swoven Pokharel")
        #expect(decoded.rasiChart.planets.count == 9)
    }

    @Test("JSON with vargas and dashas round-trips")
    func jsonFullRoundTrip() async throws {
        let chart = await swovenChart()
        let vargaCalc = VargaCalculator()
        let vargas = VargaType.allCases.map { vargaCalc.computeVarga($0, from: chart) }
        let dashaCalc = VimshottariCalculator()
        let dashas = dashaCalc.computeDashas(from: chart)

        let exporter = ChartExporter()
        let export = exporter.buildExport(chart: chart, vargas: vargas, dashas: dashas)

        let json = try exporter.toJSON(export)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChartExport.self, from: json.data(using: .utf8)!)
        #expect(decoded.divisionalCharts.count == 16)
        #expect(decoded.vimshottariDasha?.mahaDashas.count == 9)
    }

    // MARK: - Markdown Export

    @Test("Markdown export contains all sections")
    func markdownSections() async throws {
        let chart = await swovenChart()
        let vargaCalc = VargaCalculator()
        let vargas = VargaType.allCases.map { vargaCalc.computeVarga($0, from: chart) }
        let dashaCalc = VimshottariCalculator()
        let dashas = dashaCalc.computeDashas(from: chart)

        let exporter = ChartExporter()
        let export = exporter.buildExport(chart: chart, vargas: vargas, dashas: dashas)
        let md = exporter.toMarkdown(export)

        #expect(md.hasPrefix("---\n"))
        #expect(md.contains("ayanamsa: Lahiri"))
        #expect(md.contains("# Birth Chart: Swoven Pokharel"))
        #expect(md.contains("## Rasi Chart (D1)"))
        #expect(md.contains("| Sun |"))
        #expect(md.contains("## Divisional Charts"))
        #expect(md.contains("## Vimshottari Dasha"))
        #expect(md.contains("**Current"))
        #expect(md.contains("### Maha Dasha Timeline"))
    }

    @Test("Markdown Lagna line present when birth time known")
    func markdownLagna() async throws {
        let chart = await swovenChart()
        let exporter = ChartExporter()
        let export = exporter.buildExport(chart: chart)
        let md = exporter.toMarkdown(export)

        #expect(md.contains("**Lagna:** Gemini"))
    }

    @Test("Export without vargas or dashas works")
    func minimalExport() async throws {
        let chart = await swovenChart()
        let exporter = ChartExporter()
        let export = exporter.buildExport(chart: chart)

        #expect(export.divisionalCharts.isEmpty)
        #expect(export.vimshottariDasha == nil)

        let json = try exporter.toJSON(export)
        #expect(json.contains("Swoven Pokharel"))

        let md = exporter.toMarkdown(export)
        #expect(!md.contains("## Divisional Charts"))
        #expect(!md.contains("## Vimshottari Dasha"))
    }

    @Test("Swoven full export — print JSON and Markdown")
    func swovenFullExport() async throws {
        let chart = await swovenChart()
        let vargaCalc = VargaCalculator()
        let vargas = VargaType.allCases.map { vargaCalc.computeVarga($0, from: chart) }
        let dashaCalc = VimshottariCalculator()
        let dashas = dashaCalc.computeDashas(from: chart)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2026, month: 4, day: 23))!

        let exporter = ChartExporter()
        let export = exporter.buildExport(
            chart: chart, vargas: vargas, dashas: dashas,
            currentDate: today
        )

        let json = try exporter.toJSON(export)
        print("=== JSON Export (first 500 chars) ===")
        print(String(json.prefix(500)))
        print("... (\(json.count) total characters)")

        let md = exporter.toMarkdown(export)
        print("\n=== Markdown Export ===")
        print(md)

        #expect(export.vimshottariDasha?.currentDasha?.maha == "Mercury")
        #expect(export.vimshottariDasha?.currentDasha?.antar == "Venus")
    }
}
