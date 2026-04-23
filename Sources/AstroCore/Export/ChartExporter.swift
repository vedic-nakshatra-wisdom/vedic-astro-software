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
        karakas: CharaKarakaResult? = nil,
        shadbala: ShadBalaResult? = nil,
        ishtaDevta: IshtaDevtaResult? = nil,
        arudhaLagna: ArudhaLagnaResult? = nil,
        bhriguBindu: BhriguBinduResult? = nil,
        currentDate: Date = Date()
    ) -> ChartExport {

        // 1. Metadata
        let metadata = ExportMetadata(
            engineVersion: "0.5",
            exportDate: currentDate,
            ayanamsa: chart.ayanamsaType.rawValue,
            ayanamsaValue: chart.ayanamsaValue,
            houseSystem: chart.houseSystem.rawValue,
            nodeType: chart.nodeType.rawValue
        )

        // 2. Birth Data
        let tzSeconds = chart.birthData.timeZoneOffset
        let tzHours = tzSeconds / 3600.0
        let tzSign = tzHours >= 0 ? "+" : ""
        let birthDataExport = BirthDataExport(
            name: chart.birthData.name,
            dateTimeUTC: chart.birthData.dateTimeUTC,
            timeZoneOffsetSeconds: tzSeconds,
            timeZoneOffsetHours: "\(tzSign)\(String(format: "%.2f", tzHours))",
            latitude: chart.birthData.latitude,
            longitude: chart.birthData.longitude,
            hasBirthTime: chart.birthData.hasBirthTime
        )

        // 3. Rasi Chart
        let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]
        let planetExports: [PlanetExport] = planetOrder.compactMap { planet in
            guard let pos = chart.planets[planet] else { return nil }
            return PlanetExport(
                planet: planet.rawValue,
                sign: pos.sign.name,
                longitude: pos.longitude,
                degreeInSign: pos.formattedDegree,
                nakshatra: pos.nakshatra.name,
                pada: pos.nakshatraPada,
                house: chart.house(of: planet),
                isRetrograde: pos.isRetrograde
            )
        }

        let ascExport: AscendantExport?
        if let asc = chart.ascendant {
            ascExport = AscendantExport(
                sign: asc.sign.name,
                degree: asc.formattedDegree,
                longitude: asc.longitude,
                nakshatra: asc.nakshatra.name,
                pada: asc.nakshatraPada
            )
        } else {
            ascExport = nil
        }

        let rasiChart = RasiChartExport(
            ascendant: ascExport,
            planets: planetExports,
            houseCusps: chart.houseCusps
        )

        // 4. Divisional Charts — sorted by division number
        let vargaExports = vargas
            .map { VargaExport(from: $0) }
            .sorted { $0.division < $1.division }

        // 5. Vimshottari Dasha
        let dashaExport: VimshottariDashaExport?
        if let dashas = dashas {
            let calc = VimshottariCalculator()
            let path = calc.activeDashaPath(in: dashas, at: currentDate)

            let current: VimshottariDashaExport.CurrentDashaExport?
            if !path.isEmpty {
                current = VimshottariDashaExport.CurrentDashaExport(
                    asOf: currentDate,
                    maha: path[0].planet.rawValue,
                    antar: path.count > 1 ? path[1].planet.rawValue : nil,
                    pratyantar: path.count > 2 ? path[2].planet.rawValue : nil
                )
            } else {
                current = nil
            }

            let mahas = dashas.map { maha in
                VimshottariDashaExport.MahaDashaExport(
                    planet: maha.planet.rawValue,
                    startDate: maha.startDate,
                    endDate: maha.endDate,
                    years: maha.durationDays / 365.25,
                    antarDashas: maha.subPeriods.map { antar in
                        VimshottariDashaExport.AntarDashaExport(
                            planet: antar.planet.rawValue,
                            startDate: antar.startDate,
                            endDate: antar.endDate
                        )
                    }
                )
            }

            dashaExport = VimshottariDashaExport(
                currentDasha: current,
                mahaDashas: mahas
            )
        } else {
            dashaExport = nil
        }

        // 8. Jaimini
        let jaiminiExport: JaiminiExport?
        if karakas != nil || ishtaDevta != nil || arudhaLagna != nil {
            let ishtaExport: IshtaDevtaExport?
            if let ishta = ishtaDevta {
                ishtaExport = IshtaDevtaExport(
                    atmakaraka: ishta.atmakaraka.rawValue,
                    karakamsaSign: ishta.karakamsa.karakamsaSign.name,
                    twelfthFromKarakamsa: ishta.twelfthSign.name,
                    planetsInTwelfth: ishta.planetsInTwelfth.map { $0.rawValue },
                    significator: ishta.significator.rawValue,
                    deity: ishta.deity.rawValue
                )
            } else {
                ishtaExport = nil
            }

            jaiminiExport = JaiminiExport(
                charaKarakas: karakas,
                karakamsa: ishtaDevta?.karakamsa,
                ishtaDevta: ishtaExport,
                arudhaLagnas: arudhaLagna
            )
        } else {
            jaiminiExport = nil
        }

        // 9. Special Points
        let specialExport: SpecialPointsExport?
        if bhriguBindu != nil {
            specialExport = SpecialPointsExport(bhriguBindu: bhriguBindu)
        } else {
            specialExport = nil
        }

        return ChartExport(
            metadata: metadata,
            birthData: birthDataExport,
            rasiChart: rasiChart,
            divisionalCharts: vargaExports,
            vimshottariDasha: dashaExport,
            ashtakavarga: ashtakavarga,
            shadbala: shadbala,
            jaimini: jaiminiExport,
            specialPoints: specialExport
        )
    }

    // MARK: - JSON Export

    /// Export to JSON string. Field order follows struct declaration order.
    public func toJSON(_ export: ChartExport, prettyPrint: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted]
        }
        let data = try encoder.encode(export)
        return String(data: data, encoding: .utf8)!
    }

    // MARK: - Markdown Export

    /// Export to Markdown string.
    public func toMarkdown(_ export: ChartExport) -> String {
        var md = ""
        let isoFormatter = ISO8601DateFormatter()

        // YAML frontmatter
        md += "---\n"
        md += "engine: VedicAstro v\(export.metadata.engineVersion)\n"
        md += "ayanamsa: \(export.metadata.ayanamsa)\n"
        md += "house_system: \(export.metadata.houseSystem)\n"
        md += "node_type: \(export.metadata.nodeType)\n"
        md += "exported: \(isoFormatter.string(from: export.metadata.exportDate))\n"
        md += "---\n\n"

        // Birth Data
        let bd = export.birthData
        md += "# Birth Chart: \(bd.name)\n\n"

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.timeZone = TimeZone(identifier: "UTC")
        md += "- **Date/Time (UTC):** \(df.string(from: bd.dateTimeUTC))\n"
        md += "- **Timezone Offset:** \(bd.timeZoneOffsetHours) hours\n"
        md += "- **Location:** \(String(format: "%.4f", bd.latitude))\u{00B0}N, \(String(format: "%.4f", bd.longitude))\u{00B0}E\n"
        md += "- **Ayanamsa:** \(export.metadata.ayanamsa)"
        md += " (\(String(format: "%.4f", export.metadata.ayanamsaValue))\u{00B0})\n"
        md += "\n"

        // Rasi Chart
        md += "## Rasi Chart (D1)\n\n"
        if let asc = export.rasiChart.ascendant {
            md += "**Lagna:** \(asc.sign) \(asc.degree)\n\n"
        }

        md += "| Planet | Sign | Degree | Nakshatra | Pada | Retro | House |\n"
        md += "|--------|------|--------|-----------|------|-------|-------|\n"
        for p in export.rasiChart.planets {
            let retro = p.isRetrograde ? "R" : ""
            let house = p.house.map { "H\($0)" } ?? "-"
            md += "| \(p.planet) | \(p.sign) | \(p.degreeInSign) | \(p.nakshatra) | \(p.pada) | \(retro) | \(house) |\n"
        }
        md += "\n"

        // Divisional Charts
        if !export.divisionalCharts.isEmpty {
            md += "## Divisional Charts (Shodasha Varga)\n\n"

            var header = "| Planet"
            var separator = "|--------"
            for varga in export.divisionalCharts {
                header += " | \(varga.shortName)"
                separator += "|------"
            }
            header += " |"
            separator += "|"
            md += header + "\n" + separator + "\n"

            // Lagna row
            var lagnaRow = "| **Lagna**"
            for varga in export.divisionalCharts {
                lagnaRow += " | \(abbreviateSign(varga.ascendantSign ?? "-"))"
            }
            lagnaRow += " |"
            md += lagnaRow + "\n"

            let planetOrder = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu"]
            for planetName in planetOrder {
                var row = "| \(planetName)"
                for varga in export.divisionalCharts {
                    let sign = varga.placements.first(where: { $0.planet == planetName })?.sign ?? "-"
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

            var header = "| Planet"
            for s in signHeaders { header += " | \(s)" }
            header += " | Total |\n"
            md += header

            var separator = "|--------"
            for _ in signs { separator += "|----" }
            separator += "|-------|\n"
            md += separator

            let astvOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]
            for planet in astvOrder {
                if let bav = ashtakavarga.bpiBindus[planet] {
                    var row = "| \(planet.rawValue)"
                    for b in bav.bindus { row += " | \(b)" }
                    row += " | \(bav.total) |\n"
                    md += row
                }
            }

            var savRow = "| **SAV**"
            for b in ashtakavarga.sarvashtakavarga.bindus { savRow += " | \(b)" }
            savRow += " | \(ashtakavarga.sarvashtakavarga.total) |\n"
            md += savRow
            md += "\n"
        }

        // Shadbala
        if let shadbala = export.shadbala {
            md += "## Shadbala (Six-fold Strength)\n\n"
            md += "| Planet | Sthana | Dig | Kala | Total | Rupas |\n"
            md += "|--------|--------|-----|------|-------|-------|\n"
            let order: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]
            for planet in order {
                if let b = shadbala.planetBala[planet] {
                    md += "| \(planet.rawValue) | \(String(format: "%.1f", b.sthanaBala)) | \(String(format: "%.1f", b.digBala)) | \(String(format: "%.1f", b.kalaBala)) | \(String(format: "%.1f", b.totalVirupas)) | \(String(format: "%.2f", b.totalRupas)) |\n"
                }
            }
            md += "\n"
        }

        // Jaimini
        if let jaimini = export.jaimini {
            if let karakas = jaimini.charaKarakas {
                let system = karakas.isEightKaraka ? "8-Karaka" : "7-Karaka"
                md += "## Jaimini Chara Karakas (\(system) System)\n\n"
                md += "| Karaka | Abbreviation | Planet | Degree |\n"
                md += "|--------|--------------|--------|--------|\n"
                for entry in karakas.ranking {
                    md += "| \(entry.karaka.rawValue) | \(entry.karaka.abbreviation) | \(entry.planet.rawValue) | \(String(format: "%.2f", entry.degreeInSign))\u{00B0} |\n"
                }
                md += "\n"
            }

            if let ishta = jaimini.ishtaDevta {
                md += "## Karakamsa & Ishta Devta\n\n"
                md += "- **Atmakaraka:** \(ishta.atmakaraka)\n"
                md += "- **Karakamsa (AK in D9):** \(ishta.karakamsaSign)\n"
                md += "- **12th from Karakamsa:** \(ishta.twelfthFromKarakamsa)\n"
                if !ishta.planetsInTwelfth.isEmpty {
                    md += "- **Planets in 12th:** \(ishta.planetsInTwelfth.joined(separator: ", "))\n"
                }
                md += "- **Significator:** \(ishta.significator)\n"
                md += "- **Ishta Devta:** \(ishta.deity)\n"
                md += "\n"
            }

            if let arudha = jaimini.arudhaLagnas {
                md += "## Arudha Lagnas\n\n"
                md += "| House | Arudha | Label |\n"
                md += "|-------|--------|-------|\n"
                let labels = [
                    1: "AL (Pada Lagna)", 2: "A2 (Dhana)", 3: "A3",
                    4: "A4 (Matri)", 5: "A5 (Mantra)", 6: "A6 (Roga)",
                    7: "A7 (Dara)", 8: "A8 (Mrityu)", 9: "A9 (Dharma)",
                    10: "A10 (Rajya)", 11: "A11 (Labha)", 12: "UL (Upapada)"
                ]
                for house in 1...12 {
                    if let sign = arudha.arudha(ofHouse: house) {
                        md += "| H\(house) | \(sign.name) | \(labels[house] ?? "A\(house)") |\n"
                    }
                }
                md += "\n"
            }
        }

        // Special Points
        if let sp = export.specialPoints, let bb = sp.bhriguBindu {
            md += "## Bhrigu Bindu\n\n"
            md += "- **Position:** \(bb.formattedPosition)\n"
            md += "- **Nakshatra:** \(bb.nakshatra.name) (Pada \(bb.pada))\n"
            if let h = bb.house { md += "- **House:** H\(h)\n" }
            if let sav = bb.savScore { md += "- **SAV Score:** \(sav)\n" }
            md += "\n"
        }

        // Vimshottari Dasha
        if let dasha = export.vimshottariDasha {
            md += "## Vimshottari Dasha\n\n"

            if let current = dasha.currentDasha {
                md += "**Current (\(isoFormatter.string(from: current.asOf))):** "
                md += current.maha
                if let antar = current.antar { md += " / \(antar)" }
                if let pratyantar = current.pratyantar { md += " / \(pratyantar)" }
                md += "\n\n"
            }

            let dashaDF = DateFormatter()
            dashaDF.dateFormat = "yyyy-MM-dd"
            dashaDF.timeZone = TimeZone(identifier: "UTC")

            md += "### Maha Dasha Timeline\n\n"
            md += "| Planet | Start | End | Years |\n"
            md += "|--------|-------|-----|-------|\n"
            for maha in dasha.mahaDashas {
                md += "| \(maha.planet) | \(dashaDF.string(from: maha.startDate)) | \(dashaDF.string(from: maha.endDate)) | \(String(format: "%.1f", maha.years)) |\n"
            }
            md += "\n"

            md += "### Antar Dasha Breakdown\n\n"
            for maha in dasha.mahaDashas {
                if maha.antarDashas.isEmpty { continue }
                md += "**\(maha.planet) Maha Dasha**\n\n"
                md += "| Antar | Start | End |\n"
                md += "|-------|-------|-----|\n"
                for antar in maha.antarDashas {
                    md += "| \(antar.planet) | \(dashaDF.string(from: antar.startDate)) | \(dashaDF.string(from: antar.endDate)) |\n"
                }
                md += "\n"
            }
        }

        return md
    }

    // MARK: - Helpers

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
