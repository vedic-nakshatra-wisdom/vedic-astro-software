import SwiftUI
import AstroCore

struct BhavaChalitView: View {
    let viewModel: ChartViewModel

    private let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let chart = viewModel.chart, let chalit = viewModel.bhavaChalit {
                    // Diamond charts: Rasi vs Bhava Chalit side by side
                    HStack(alignment: .top, spacing: 16) {
                        NorthIndianChartView(chart: chart, title: "Rasi (D1)", size: 320)
                        chalitDiamondChart(chart: chart, chalit: chalit, size: 320)
                    }
                    .frame(maxWidth: .infinity)

                    // Comparison table
                    comparisonTable(chart: chart, chalit: chalit)

                    // Cusp details
                    cuspTable(chart: chart, chalit: chalit)
                } else {
                    Text("Birth time required for Bhava Chalit chart.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .navigationTitle("Bhava Chalit")
    }

    // MARK: - Chalit Diamond Chart

    private func chalitDiamondChart(chart: BirthChart, chalit: BhavaChalitResult, size: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text("Bhava Chalit")
                .font(.headline)

            ZStack {
                Rectangle()
                    .fill(Color(nsColor: .controlBackgroundColor))

                chartLines(size: size)
                    .stroke(Color.primary.opacity(0.5), lineWidth: 1.2)

                Rectangle()
                    .stroke(Color.primary, lineWidth: 2.5)

                ForEach(1...12, id: \.self) { house in
                    chalitHouseContent(house: house, chart: chart, chalit: chalit, size: size)
                }

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
    private func chalitHouseContent(house: Int, chart: BirthChart, chalit: BhavaChalitResult, size: CGFloat) -> some View {
        let center = houseCentroid(house)
        let sign = chart.signOf(house: house)
        let isKendra = [1, 4, 7, 10].contains(house)

        let planets = chalit.planetsIn(bhava: house)

        VStack(spacing: 1) {
            Text(sign.map { "\($0.number)" } ?? "-")
                .font(.system(size: isKendra ? 10 : 9, weight: .bold))
                .foregroundStyle(signColor(sign))

            if !planets.isEmpty {
                VStack(spacing: 1) {
                    ForEach(planetRows(planets, maxPerRow: isKendra ? 4 : 3), id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(row, id: \.self) { planet in
                                let shifted = chalit.hasShifted(planet: planet, rasiHouse: chart.house(of: planet))
                                Text(abbrev(planet))
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(planetColor(planet))
                                    .underline(shifted, color: .red)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: houseFrameWidth(house, size: size), height: houseFrameHeight(house, size: size))
        .position(x: center.x * size, y: center.y * size)
    }

    // MARK: - Comparison Table

    private func comparisonTable(chart: BirthChart, chalit: BhavaChalitResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rasi vs Bhava Chalit Comparison")
                .font(.headline)
            Text("Underlined planets have shifted houses. Red indicates the shift.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Planet").font(.caption.bold()).foregroundStyle(.secondary)
                        .gridColumnAlignment(.leading)
                    Text("Sign").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Degree").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Rasi House").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Bhava House").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Shifted?").font(.caption.bold()).foregroundStyle(.secondary)
                }

                Divider()

                ForEach(planetOrder, id: \.self) { planet in
                    if let pos = chart.position(of: planet) {
                        let rasiHouse = chart.house(of: planet)
                        let bhavaHouse = chalit.planetBhava[planet]
                        let shifted = chalit.hasShifted(planet: planet, rasiHouse: rasiHouse)

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
                            Text(rasiHouse.map { "H\($0)" } ?? "-")
                                .frame(width: 50, alignment: .center)
                            Text(bhavaHouse.map { "H\($0)" } ?? "-")
                                .fontWeight(.bold)
                                .foregroundStyle(shifted ? .red : .primary)
                                .frame(width: 60, alignment: .center)
                            Text(shifted ? "YES" : "-")
                                .font(.caption.bold())
                                .foregroundStyle(shifted ? Color.red : Color.gray)
                                .frame(width: 50, alignment: .center)
                        }
                        .background(shifted ? .red.opacity(0.04) : .clear)
                    }
                }
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Cusp Table

    private func cuspTable(chart: BirthChart, chalit: BhavaChalitResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bhava Cusps & Midpoints")
                .font(.headline)
            Text("Equal house system: Ascendant = midpoint of 1st bhava, each bhava = 30°")
                .font(.caption)
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("Bhava").font(.caption.bold()).foregroundStyle(.secondary)
                        .gridColumnAlignment(.leading)
                    Text("Cusp Start").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Midpoint").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Sign").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Planets").font(.caption.bold()).foregroundStyle(.secondary)
                }

                Divider()

                ForEach(1...12, id: \.self) { house in
                    let cusp = chalit.cusps[house - 1]
                    let madhya = chalit.madhyas[house - 1]
                    let sign = Sign.from(longitude: madhya)
                    let planets = chalit.planetsIn(bhava: house)

                    GridRow {
                        Text("H\(house)")
                            .font(.caption.bold())
                        Text(formatDegree(cusp))
                            .font(.system(.caption, design: .monospaced))
                        Text(formatDegree(madhya))
                            .font(.system(.caption, design: .monospaced))
                        Text("\(sign.number)")
                            .font(.caption.bold())
                            .foregroundStyle(signColor(sign))
                        HStack(spacing: 4) {
                            if planets.isEmpty {
                                Text("-")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                ForEach(planets, id: \.self) { planet in
                                    Text(abbrev(planet))
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(planetColor(planet))
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Helpers

    private func formatDegree(_ lon: Double) -> String {
        let sign = Sign.from(longitude: lon)
        let deg = lon - Double(sign.rawValue) * 30.0
        let d = Int(deg)
        let m = Int((deg - Double(d)) * 60.0)
        return "\(sign.shortName) \(d)°\(String(format: "%02d", m))'"
    }

    private func abbrev(_ planet: Planet) -> String {
        let retro = viewModel.chart?.position(of: planet)?.isRetrograde == true ? "(R)" : ""
        let name: String
        switch planet {
        case .sun: name = "Su"
        case .moon: name = "Mo"
        case .mars: name = "Ma"
        case .mercury: name = "Me"
        case .jupiter: name = "Ju"
        case .venus: name = "Ve"
        case .saturn: name = "Sa"
        case .rahu: name = "Ra"
        case .ketu: name = "Ke"
        }
        return name + retro
    }

    private func planetRows(_ planets: [Planet], maxPerRow: Int) -> [[Planet]] {
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
}
