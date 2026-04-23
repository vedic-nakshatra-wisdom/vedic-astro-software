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

        #expect(export.vargas.count == 16)
        #expect(export.dashas?.count == 9)
        #expect(export.currentDasha != nil)
        #expect(export.metadata.engineVersion == "0.3")
        #expect(export.metadata.ayanamsa == "Lahiri")
    }

    // MARK: - VargaExport

    @Test("VargaExport strips sourceChart reference")
    func vargaExportLightweight() async throws {
        let chart = await swovenChart()
        let vargaCalc = VargaCalculator()
        let d9 = vargaCalc.computeVarga(.d9, from: chart)
        let export = VargaExport(from: d9)

        #expect(export.name == "Navamsa")
        #expect(export.shortName == "D9")
        #expect(export.placements.count == 9)
        #expect(export.ascendantSign != nil)
        // Verify it encodes cleanly (no BirthChart reference)
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

        // Verify it round-trips
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChartExport.self, from: json.data(using: .utf8)!)
        #expect(decoded.chart.birthData.name == "Swoven Pokharel")
        #expect(decoded.chart.planets.count == 9)
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
        #expect(decoded.vargas.count == 16)
        #expect(decoded.dashas?.count == 9)
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

        // YAML frontmatter
        #expect(md.hasPrefix("---\n"))
        #expect(md.contains("ayanamsa: Lahiri"))

        // Birth data section
        #expect(md.contains("# Birth Chart: Swoven Pokharel"))

        // D1 chart table
        #expect(md.contains("## Rasi Chart (D1)"))
        #expect(md.contains("| Sun |"))
        #expect(md.contains("Purva Phalguni"))

        // Varga table
        #expect(md.contains("## Divisional Charts"))
        #expect(md.contains("| D1 |"))
        #expect(md.contains("| D9 |"))
        #expect(md.contains("| D60 |"))

        // Dasha section
        #expect(md.contains("## Vimshottari Dasha"))
        #expect(md.contains("**Current"))
        #expect(md.contains("Mercury"))
        #expect(md.contains("### Maha Dasha Timeline"))
        #expect(md.contains("### Antar Dasha Breakdown"))

        // Print for visual inspection
        print(md)
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

        #expect(export.vargas.isEmpty)
        #expect(export.dashas == nil)

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

        // Use a fixed date for reproducible output
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

        // Verify current dasha in export
        #expect(export.currentDasha?.maha == "Mercury")
        #expect(export.currentDasha?.antar == "Venus")
    }
}
