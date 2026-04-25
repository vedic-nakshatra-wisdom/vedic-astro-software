import SwiftUI
import AstroCore

struct TransitView: View {
    let viewModel: ChartViewModel
    @State private var hasLoaded = false

    private let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let chart = viewModel.chart, viewModel.transitPositions != nil {
                    // Header with transit date
                    transitHeader

                    // Diamond charts side by side: Natal vs Transit
                    HStack(alignment: .top, spacing: 16) {
                        NorthIndianChartView(chart: chart, title: "Natal (D1)", size: 320)
                        transitDiamondChart(chart: chart, size: 320)
                    }
                    .frame(maxWidth: .infinity)

                    // Transit positions table
                    transitTable(chart: chart)

                    // Moon Tithi
                    tithiSection
                } else {
                    ProgressView("Computing transit positions...")
                }
            }
            .padding(24)
        }
        .navigationTitle("Current Transits")
        .task {
            if !hasLoaded {
                await viewModel.computeTransits()
                hasLoaded = true
            }
        }
    }

    // MARK: - Header

    private var transitHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Current Transits")
                .font(.headline)
            if let date = viewModel.transitDate {
                let df = {
                    let f = DateFormatter()
                    f.dateFormat = "EEEE, d MMMM yyyy 'at' HH:mm z"
                    f.timeZone = .current
                    return f
                }()
                Text("Planetary positions as of \(df.string(from: date))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let lagna = viewModel.chart?.lagnaSign {
                Text("Mapped to natal houses (\(lagna.name) Lagna)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Transit Diamond Chart

    private func transitDiamondChart(chart: BirthChart, size: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text("Transits in Natal Houses")
                .font(.headline)

            ZStack {
                Rectangle()
                    .fill(Color(nsColor: .controlBackgroundColor))

                chartLines(size: size)
                    .stroke(Color.primary.opacity(0.5), lineWidth: 1.2)

                Rectangle()
                    .stroke(Color.primary, lineWidth: 2.5)

                ForEach(1...12, id: \.self) { house in
                    transitHouseContent(house: house, chart: chart, size: size)
                }

                // Asc marker
                Text("Asc")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(.red)
                    .position(x: size * 0.5, y: size * 0.10)
            }
            .frame(width: size, height: size)
            .clipShape(Rectangle())
        }
    }

    @ViewBuilder
    private func transitHouseContent(house: Int, chart: BirthChart, size: CGFloat) -> some View {
        let center = houseCentroid(house)
        let sign = chart.signOf(house: house)
        let isKendra = [1, 4, 7, 10].contains(house)

        // Find transit planets in this natal house
        let transitPlanets = planetOrder.filter { viewModel.transitHouse(for: $0) == house }

        VStack(spacing: 1) {
            // Sign number with element color
            Text(sign.map { "\($0.number)" } ?? "-")
                .font(.system(size: isKendra ? 10 : 9, weight: .bold))
                .foregroundStyle(signColor(sign))

            // Transit planets
            if !transitPlanets.isEmpty {
                VStack(spacing: 1) {
                    ForEach(transitPlanetRows(transitPlanets, maxPerRow: isKendra ? 4 : 3), id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(row, id: \.self) { planet in
                                Text(planetAbbrev(planet))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(planetColor(planet))
                            }
                        }
                    }
                }
            }
        }
        .frame(width: houseFrameWidth(house, size: size), height: houseFrameHeight(house, size: size))
        .position(x: center.x * size, y: center.y * size)
    }

    // MARK: - Transit Table

    private func transitTable(chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transit Positions")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Planet").font(.caption.bold()).foregroundStyle(.secondary)
                        .gridColumnAlignment(.leading)
                    Text("Sign").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Degree").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Nakshatra").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Pada").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Natal House").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Retro").font(.caption.bold()).foregroundStyle(.secondary)
                }

                Divider()

                ForEach(planetOrder, id: \.self) { planet in
                    if let pos = viewModel.transitPositions?[planet] {
                        let natalHouse = viewModel.transitHouse(for: planet)
                        GridRow {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(planetColor(planet))
                                    .frame(width: 10, height: 10)
                                Text(planet.rawValue)
                                    .fontWeight(.semibold)
                            }
                            Text("\(pos.sign.number)")
                                .foregroundStyle(signColor(pos.sign))
                                .fontWeight(.bold)
                            Text(pos.formattedDegree)
                                .font(.system(.body, design: .monospaced))
                            Text(pos.nakshatra.name)
                            Text("\(pos.nakshatraPada)")
                                .frame(width: 30, alignment: .center)
                            Text(natalHouse.map { "H\($0)" } ?? "-")
                                .fontWeight(.bold)
                                .foregroundStyle(houseColor(natalHouse))
                                .frame(width: 50, alignment: .center)
                            Text(pos.isRetrograde ? "R" : "")
                                .foregroundStyle(.red)
                                .fontWeight(.bold)
                                .frame(width: 20, alignment: .center)
                        }
                    }
                }
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Tithi Section

    private var tithiSection: some View {
        let tithi = currentTithi
        return VStack(alignment: .leading, spacing: 12) {
            Text("Moon Tithi")
                .font(.headline)

            VStack(spacing: 16) {
                // Main tithi card
                HStack(spacing: 20) {
                    // Moon phase icon
                    VStack(spacing: 4) {
                        Text(tithi.moonPhaseEmoji)
                            .font(.system(size: 48))
                        Text(tithi.paksha)
                            .font(.caption.bold())
                            .foregroundStyle(tithi.isShukla ? .yellow : .indigo)
                    }
                    .frame(width: 80)

                    VStack(alignment: .leading, spacing: 6) {
                        // Tithi name
                        Text(tithi.name)
                            .font(.title2.bold())

                        // Paksha and number
                        HStack(spacing: 8) {
                            Text(tithi.paksha)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(tithi.isShukla ? .yellow.opacity(0.15) : .indigo.opacity(0.15))
                                .clipShape(Capsule())

                            Text("Tithi #\(tithi.number)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Deity
                        HStack(spacing: 4) {
                            Text("Deity:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(tithi.deity)
                                .font(.caption.bold())
                        }

                        // Transition timing
                        if let endDate = tithi.tithiEndDate {
                            let tz = TimeZone(identifier: viewModel.timeZoneID) ?? .current
                            let timeFmt = {
                                let f = DateFormatter()
                                f.dateFormat = "h:mm a"
                                f.timeZone = tz
                                return f
                            }()
                            let dayFmt = {
                                let f = DateFormatter()
                                f.dateFormat = "d MMM yyyy"
                                f.timeZone = tz
                                return f
                            }()
                            let tzAbbr = tz.abbreviation(for: endDate) ?? tz.identifier

                            Divider().frame(width: 220)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 4) {
                                    Text(tithi.name)
                                        .font(.caption.bold())
                                    Text("upto")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(timeFmt.string(from: endDate)) \(tzAbbr)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.orange)
                                }

                                HStack(spacing: 4) {
                                    Text("then")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(tithi.nextTithiName)
                                        .font(.caption.bold())
                                        .foregroundStyle(tithi.isShukla && tithi.number < 15 ? .yellow : .indigo)
                                    Text("(\(dayFmt.string(from: endDate)))")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Progress in tithi
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(.gray.opacity(0.2), lineWidth: 6)
                                .frame(width: 60, height: 60)
                            Circle()
                                .trim(from: 0, to: tithi.progress)
                                .stroke(
                                    tithi.isShukla ? Color.yellow : Color.indigo,
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                            Text(String(format: "%.0f%%", tithi.progress * 100))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                        }
                        Text("elapsed")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tithi.isShukla ? .yellow.opacity(0.03) : .indigo.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tithi.isShukla ? .yellow.opacity(0.15) : .indigo.opacity(0.15), lineWidth: 1)
                        )
                )

                // Details grid
                HStack(spacing: 16) {
                    tithiDetail("Sun-Moon Angle", value: String(format: "%.2f°", tithi.sunMoonAngle))
                    tithiDetail("Moon Sign", value: "\(tithi.moonSign.name) (\(tithi.moonSign.number))")
                    tithiDetail("Moon Nakshatra", value: tithi.moonNakshatra)
                    tithiDetail("Karana", value: tithi.karana)
                }
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func tithiDetail(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tithi Computation

    private struct TithiInfo {
        let number: Int       // 1-30
        let name: String
        let paksha: String
        let isShukla: Bool
        let deity: String
        let progress: Double  // 0-1 within current tithi
        let sunMoonAngle: Double
        let moonSign: Sign
        let moonNakshatra: String
        let moonPhaseEmoji: String
        let karana: String
        let tithiEndDate: Date?    // when current tithi ends
        let nextTithiName: String  // name of next tithi
    }

    private var currentTithi: TithiInfo {
        let moonLon = viewModel.transitPositions?[.moon]?.longitude ?? 0
        let sunLon = viewModel.transitPositions?[.sun]?.longitude ?? 0
        let moonPos = viewModel.transitPositions?[.moon]

        // Sun-Moon angular distance (0-360)
        var angle = moonLon - sunLon
        if angle < 0 { angle += 360.0 }

        // Tithi number: each tithi = 12°
        let tithiIndex = Int(angle / 12.0)  // 0-29
        let tithiNumber = tithiIndex + 1     // 1-30
        let progress = (angle - Double(tithiIndex) * 12.0) / 12.0

        let isShukla = tithiNumber <= 15
        let paksha = isShukla ? "Shukla Paksha" : "Krishna Paksha"

        let tithiNames = [
            "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
            "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
            "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Purnima",
            "Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami",
            "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami",
            "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi", "Amavasya"
        ]

        let tithiDeities = [
            "Agni", "Brahma", "Gauri", "Ganapati", "Naaga",
            "Kartikeya", "Surya", "Shiva", "Durga", "Yama",
            "Vishnu", "Hari", "Kamadeva", "Shiva", "Chandra",
            "Agni", "Brahma", "Gauri", "Ganapati", "Naaga",
            "Kartikeya", "Surya", "Shiva", "Durga", "Yama",
            "Vishnu", "Hari", "Kamadeva", "Shiva", "Pitri"
        ]

        let name = tithiNames[tithiIndex]
        let deity = tithiDeities[tithiIndex]

        // Moon phase emoji based on tithi
        let emoji: String
        switch tithiNumber {
        case 1:        emoji = "🌑"  // New moon
        case 2...4:    emoji = isShukla ? "🌒" : "🌘"
        case 5...8:    emoji = isShukla ? "🌓" : "🌗"
        case 9...12:   emoji = isShukla ? "🌔" : "🌖"
        case 13...14:  emoji = isShukla ? "🌔" : "🌘"
        case 15:       emoji = isShukla ? "🌕" : "🌑"
        case 16...19:  emoji = "🌖"
        case 20...23:  emoji = "🌗"
        case 24...27:  emoji = "🌘"
        case 28...30:  emoji = "🌘"
        default:       emoji = "🌙"
        }

        // Karana (half-tithi): each tithi has 2 karanas, each = 6°
        let karanaIndex = Int(angle / 6.0) % 60
        let karanas = [
            "Kimstughna", "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Bava", "Balava", "Kaulava", "Taitila", "Garaja", "Vanija", "Vishti",
            "Shakuni", "Chatushpada", "Naaga", "Kimstughna"
        ]
        let karana = karanas[min(karanaIndex, karanas.count - 1)]

        // Compute tithi end time using Moon and Sun speeds
        let moonSpeed = viewModel.transitPositions?[.moon]?.speedLongitude ?? 13.2
        let sunSpeed = viewModel.transitPositions?[.sun]?.speedLongitude ?? 1.0
        let relativeSpeed = moonSpeed - sunSpeed  // degrees/day of Moon-Sun separation

        let nextBoundary = Double(tithiIndex + 1) * 12.0
        let remainingDegrees = nextBoundary - angle
        let tithiEndDate: Date?
        if relativeSpeed > 0, let transitDate = viewModel.transitDate {
            let daysToEnd = remainingDegrees / relativeSpeed
            tithiEndDate = transitDate.addingTimeInterval(daysToEnd * 86400.0)
        } else {
            tithiEndDate = nil
        }

        // Next tithi name
        let nextIndex = (tithiIndex + 1) % 30
        let nextTithiName = tithiNames[nextIndex]

        return TithiInfo(
            number: tithiNumber,
            name: name,
            paksha: paksha,
            isShukla: isShukla,
            deity: deity,
            progress: progress,
            sunMoonAngle: angle,
            moonSign: moonPos?.sign ?? .aries,
            moonNakshatra: moonPos?.nakshatra.name ?? "",
            moonPhaseEmoji: emoji,
            karana: karana,
            tithiEndDate: tithiEndDate,
            nextTithiName: nextTithiName
        )
    }

    // MARK: - Chart Geometry

    private func chartLines(size: CGFloat) -> Path {
        Path { path in
            let s = size
            path.move(to: CGPoint(x: s * 0.5, y: 0))
            path.addLine(to: CGPoint(x: s, y: s * 0.5))
            path.addLine(to: CGPoint(x: s * 0.5, y: s))
            path.addLine(to: CGPoint(x: 0, y: s * 0.5))
            path.closeSubpath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: s, y: s))
            path.move(to: CGPoint(x: s, y: 0))
            path.addLine(to: CGPoint(x: 0, y: s))
        }
    }

    private func houseCentroid(_ house: Int) -> CGPoint {
        switch house {
        case 1:  return CGPoint(x: 0.50, y: 0.22)
        case 2:  return CGPoint(x: 0.25, y: 0.08)
        case 3:  return CGPoint(x: 0.08, y: 0.25)
        case 4:  return CGPoint(x: 0.22, y: 0.50)
        case 5:  return CGPoint(x: 0.08, y: 0.75)
        case 6:  return CGPoint(x: 0.25, y: 0.92)
        case 7:  return CGPoint(x: 0.50, y: 0.78)
        case 8:  return CGPoint(x: 0.75, y: 0.92)
        case 9:  return CGPoint(x: 0.92, y: 0.75)
        case 10: return CGPoint(x: 0.78, y: 0.50)
        case 11: return CGPoint(x: 0.92, y: 0.25)
        case 12: return CGPoint(x: 0.75, y: 0.08)
        default: return CGPoint(x: 0.50, y: 0.50)
        }
    }

    private func houseFrameWidth(_ house: Int, size: CGFloat) -> CGFloat {
        [1, 4, 7, 10].contains(house) ? size * 0.30 : size * 0.20
    }

    private func houseFrameHeight(_ house: Int, size: CGFloat) -> CGFloat {
        [1, 4, 7, 10].contains(house) ? size * 0.24 : size * 0.16
    }

    private func transitPlanetRows(_ planets: [Planet], maxPerRow: Int) -> [[Planet]] {
        var rows: [[Planet]] = []
        var current: [Planet] = []
        for p in planets {
            current.append(p)
            if current.count == maxPerRow {
                rows.append(current)
                current = []
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }

    // MARK: - Helpers

    private func planetAbbrev(_ planet: Planet) -> String {
        let retro = viewModel.transitPositions?[planet]?.isRetrograde == true ? "(R)" : ""
        return shortAbbrev(planet) + retro
    }

    private func shortAbbrev(_ planet: Planet) -> String {
        switch planet {
        case .sun: return "Su"
        case .moon: return "Mo"
        case .mars: return "Ma"
        case .mercury: return "Me"
        case .jupiter: return "Ju"
        case .venus: return "Ve"
        case .saturn: return "Sa"
        case .rahu: return "Ra"
        case .ketu: return "Ke"
        }
    }

    private func signColor(_ sign: Sign?) -> Color {
        guard let sign else { return .primary }
        switch sign.element {
        case .fire:  return .red
        case .earth: return .brown
        case .air:   return .teal
        case .water: return .blue
        }
    }

    private func planetColor(_ planet: Planet) -> Color {
        switch planet {
        case .sun:     return .orange
        case .moon:    return .blue
        case .mars:    return .red
        case .mercury: return .green
        case .jupiter: return .yellow
        case .venus:   return .pink
        case .saturn:  return .gray
        case .rahu:    return .indigo
        case .ketu:    return .brown
        }
    }

    private func houseColor(_ house: Int?) -> Color {
        guard let house else { return .primary }
        switch house {
        case 1, 4, 7, 10: return .green   // Kendra
        case 5, 9:         return .blue    // Trikona
        case 2, 11:        return .teal    // Dhana/Labha
        case 6, 8, 12:     return .red     // Dusthana
        default:           return .primary
        }
    }
}
