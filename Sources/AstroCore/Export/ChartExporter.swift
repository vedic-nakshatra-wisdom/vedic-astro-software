import Foundation

/// Exports chart data to JSON and Markdown formats.
public struct ChartExporter: Sendable {

    public init() {}

    /// Build a ChartExport from computed chart data.
    public func buildExport(
        chart: BirthChart,
        vargas: [VargaChart] = [],
        dashas: [DashaPeriod]? = nil,
        ashtakavarga: AshtakavargaResult? = nil,
        currentDate: Date = Date()
    ) -> ChartExport {
        let vargaExports = vargas.map { VargaExport(from: $0) }

        var currentDasha: ChartExport.CurrentDashaExport? = nil
        if let dashas = dashas {
            let calc = VimshottariCalculator()
            let path = calc.activeDashaPath(in: dashas, at: currentDate)
            if !path.isEmpty {
                currentDasha = ChartExport.CurrentDashaExport(
                    date: currentDate,
                    maha: path[0].planet.rawValue,
                    antar: path.count > 1 ? path[1].planet.rawValue : nil,
                    pratyantar: path.count > 2 ? path[2].planet.rawValue : nil
                )
            }
        }

        let metadata = ChartExport.ExportMetadata(
            exportDate: currentDate,
            engineVersion: "0.3",
            ayanamsa: chart.ayanamsaType.rawValue,
            houseSystem: chart.houseSystem.rawValue,
            nodeType: chart.nodeType.rawValue
        )

        return ChartExport(
            chart: chart,
            vargas: vargaExports,
            dashas: dashas,
            currentDasha: currentDasha,
            ashtakavarga: ashtakavarga,
            metadata: metadata
        )
    }

    // MARK: - JSON Export

    /// Export to JSON string.
    public func toJSON(_ export: ChartExport, prettyPrint: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(export)
        return String(data: data, encoding: .utf8)!
    }

    // MARK: - Markdown Export

    /// Export to Markdown string for Claude interpretation.
    public func toMarkdown(_ export: ChartExport) -> String {
        var md = ""

        // YAML frontmatter metadata
        md += "---\n"
        md += "engine: VedicAstro v\(export.metadata.engineVersion)\n"
        md += "ayanamsa: \(export.metadata.ayanamsa)\n"
        md += "house_system: \(export.metadata.houseSystem)\n"
        md += "node_type: \(export.metadata.nodeType)\n"
        let isoFormatter = ISO8601DateFormatter()
        md += "exported: \(isoFormatter.string(from: export.metadata.exportDate))\n"
        md += "---\n\n"

        // Birth Data
        let bd = export.chart.birthData
        md += "# Birth Chart: \(bd.name)\n\n"

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.timeZone = TimeZone(identifier: "UTC")
        md += "- **Date/Time (UTC):** \(df.string(from: bd.dateTimeUTC))\n"
        let tzHours = bd.timeZoneOffset / 3600.0
        let tzSign = tzHours >= 0 ? "+" : ""
        md += "- **Timezone Offset:** \(tzSign)\(String(format: "%.2f", tzHours)) hours\n"
        md += "- **Location:** \(String(format: "%.4f", bd.latitude))\u{00B0}N, \(String(format: "%.4f", bd.longitude))\u{00B0}E\n"
        md += "- **Ayanamsa:** \(export.chart.ayanamsaType.rawValue)"
        md += " (\(String(format: "%.4f", export.chart.ayanamsaValue))\u{00B0})\n"
        md += "\n"

        // D1 Rasi Chart
        md += "## Rasi Chart (D1)\n\n"
        if let asc = export.chart.ascendant {
            md += "**Lagna:** \(asc.sign.name) \(asc.formattedDegree)\n\n"
        }

        md += "| Planet | Sign | Degree | Nakshatra | Pada | Retro | House |\n"
        md += "|--------|------|--------|-----------|------|-------|-------|\n"

        let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]
        for planet in planetOrder {
            if let pos = export.chart.planets[planet] {
                let retro = pos.isRetrograde ? "R" : ""
                let house = export.chart.house(of: planet).map { "H\($0)" } ?? "-"
                md += "| \(planet.rawValue) | \(pos.sign.name) | \(pos.formattedDegree) | \(pos.nakshatra.name) | \(pos.nakshatraPada) | \(retro) | \(house) |\n"
            }
        }
        md += "\n"

        // Divisional Charts (compact table)
        if !export.vargas.isEmpty {
            md += "## Divisional Charts (Shodasha Varga)\n\n"

            // Build header
            var header = "| Planet"
            var separator = "|--------"
            for varga in export.vargas {
                header += " | \(varga.shortName)"
                separator += "|------"
            }
            header += " |"
            separator += "|"
            md += header + "\n" + separator + "\n"

            // Lagna row
            var lagnaRow = "| **Lagna**"
            for varga in export.vargas {
                let sign = varga.ascendantSign ?? "-"
                lagnaRow += " | \(abbreviateSign(sign))"
            }
            lagnaRow += " |"
            md += lagnaRow + "\n"

            // Planet rows
            for planet in planetOrder {
                var row = "| \(planet.rawValue)"
                for varga in export.vargas {
                    let sign = varga.placements[planet.rawValue] ?? "-"
                    row += " | \(abbreviateSign(sign))"
                }
                row += " |"
                md += row + "\n"
            }
            md += "\n"
        }

        // Ashtakavarga
        if let ashtakavarga = export.ashtakavarga {
            md += "## Ashtakavarga\n\n"

            let signs: [Sign] = Sign.allCases
            let signHeaders = signs.map { $0.shortName }

            // Header row
            var header = "| Planet"
            for s in signHeaders { header += " | \(s)" }
            header += " | Total |\n"
            md += header

            var separator = "|--------"
            for _ in signs { separator += "|----" }
            separator += "|-------|\n"
            md += separator

            let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]
            for planet in planetOrder {
                if let bav = ashtakavarga.bpiBindus[planet] {
                    var row = "| \(planet.rawValue)"
                    for b in bav.bindus {
                        row += " | \(b)"
                    }
                    row += " | \(bav.total) |\n"
                    md += row
                }
            }

            // SAV row
            var savRow = "| **SAV**"
            for b in ashtakavarga.sarvashtakavarga.bindus {
                savRow += " | \(b)"
            }
            savRow += " | \(ashtakavarga.sarvashtakavarga.total) |\n"
            md += savRow
            md += "\n"
        }

        // Vimshottari Dasha
        if let dashas = export.dashas {
            md += "## Vimshottari Dasha\n\n"

            if let current = export.currentDasha {
                md += "**Current (\(isoFormatter.string(from: current.date))):** "
                md += current.maha
                if let antar = current.antar {
                    md += " / \(antar)"
                }
                if let pratyantar = current.pratyantar {
                    md += " / \(pratyantar)"
                }
                md += "\n\n"
            }

            let dashaDF = DateFormatter()
            dashaDF.dateFormat = "yyyy-MM-dd"
            dashaDF.timeZone = TimeZone(identifier: "UTC")

            md += "### Maha Dasha Timeline\n\n"
            md += "| Planet | Start | End | Years |\n"
            md += "|--------|-------|-----|-------|\n"
            for maha in dashas {
                let years = maha.durationDays / 365.25
                md += "| \(maha.planet.rawValue) | \(dashaDF.string(from: maha.startDate)) | \(dashaDF.string(from: maha.endDate)) | \(String(format: "%.1f", years)) |\n"
            }
            md += "\n"

            // Antar Dashas for each Maha (compact)
            md += "### Antar Dasha Breakdown\n\n"
            for maha in dashas {
                if maha.subPeriods.isEmpty { continue }
                md += "**\(maha.planet.rawValue) Maha Dasha**\n\n"
                md += "| Antar | Start | End |\n"
                md += "|-------|-------|-----|\n"
                for antar in maha.subPeriods {
                    md += "| \(antar.planet.rawValue) | \(dashaDF.string(from: antar.startDate)) | \(dashaDF.string(from: antar.endDate)) |\n"
                }
                md += "\n"
            }
        }

        return md
    }

    // MARK: - Helpers

    /// Abbreviate sign name to 3 letters for compact tables
    private func abbreviateSign(_ name: String) -> String {
        let abbreviations: [String: String] = [
            "Aries": "Ari", "Taurus": "Tau", "Gemini": "Gem",
            "Cancer": "Can", "Leo": "Leo", "Virgo": "Vir",
            "Libra": "Lib", "Scorpio": "Sco", "Sagittarius": "Sag",
            "Capricorn": "Cap", "Aquarius": "Aqu", "Pisces": "Pis"
        ]
        return abbreviations[name] ?? name
    }
}
