import SwiftUI
import AstroCore

/// North Indian diamond-style horoscope chart.
///
/// Geometry: a square with an inscribed diamond (connecting midpoints of sides)
/// plus both diagonals of the outer square, creating 12 regions.
///
/// House layout — Ascendant (H1) at TOP, houses proceed COUNTER-CLOCKWISE:
///
///       ┌──────────────────────────┐
///       │╲          H12          ╱ │
///       │  ╲                   ╱   │
///       │ H1 ╲               ╱ H11│
///       │      ╲           ╱      │
///       │────────╲       ╱────────│
///       │          ╲   ╱          │
///       │ H2        ╲╱       H10 │
///       │           ╱╲           │
///       │         ╱    ╲         │
///       │────────╱       ╲───────│
///       │      ╱           ╲     │
///       │ H3 ╱               ╲ H9│
///       │  ╱                   ╲  │
///       │╱           H6          ╲│
///       └──────────────────────────┘
///    (H4=left diamond, H5=lower-left, H7=bottom diamond, H8=lower-right)
///
/// Kendra houses (1,4,7,10) occupy the inner diamond quadrilaterals.
/// Other houses occupy the corner/side triangles.
struct NorthIndianChartView: View {
    let chart: BirthChart
    let title: String
    let size: CGFloat

    init(chart: BirthChart, title: String = "Rasi (D1)", size: CGFloat = 500) {
        self.chart = chart
        self.title = title
        self.size = size
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)

            ZStack {
                // Background
                Rectangle()
                    .fill(Color(nsColor: .controlBackgroundColor))

                // Chart lines
                chartLines
                    .stroke(Color.primary.opacity(0.5), lineWidth: 1.2)

                // Outer border
                Rectangle()
                    .stroke(Color.primary, lineWidth: 2.5)

                // House contents
                ForEach(1...12, id: \.self) { house in
                    houseContent(house: house)
                }

                // Ascendant marker — small diagonal line in top-center of H1
                ascendantMarker
            }
            .frame(width: size, height: size)
            .clipShape(Rectangle())
        }
    }

    // MARK: - Chart Lines

    private var chartLines: Path {
        Path { path in
            let s = size

            // Diamond: connect midpoints of each side
            path.move(to: CGPoint(x: s * 0.5, y: 0))       // Top mid
            path.addLine(to: CGPoint(x: s, y: s * 0.5))     // Right mid
            path.addLine(to: CGPoint(x: s * 0.5, y: s))     // Bottom mid
            path.addLine(to: CGPoint(x: 0, y: s * 0.5))     // Left mid
            path.closeSubpath()

            // Diagonal: top-left corner to bottom-right corner
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: s, y: s))

            // Diagonal: top-right corner to bottom-left corner
            path.move(to: CGPoint(x: s, y: 0))
            path.addLine(to: CGPoint(x: 0, y: s))
        }
    }

    // MARK: - Ascendant Marker

    private var ascendantMarker: some View {
        // Small "Asc" label at top of house 1
        Text("Asc")
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundStyle(.red)
            .position(x: size * 0.5, y: size * 0.10)
    }

    // MARK: - House Content

    @ViewBuilder
    private func houseContent(house: Int) -> some View {
        let center = houseCentroid(house)
        let sign = chart.signOf(house: house)
        let planets = chart.planetsIn(house: house)
        let isKendra = [1, 4, 7, 10].contains(house)

        VStack(spacing: 1) {
            // Sign number (1–12)
            Text(sign.map { "\($0.number)" } ?? "—")
                .font(.system(size: isKendra ? 10 : 9, weight: .bold))
                .foregroundStyle(signColor(sign))

            // Planets in this house
            if !planets.isEmpty {
                planetLabel(planets, isKendra: isKendra)
            }
        }
        .frame(width: houseFrameWidth(house), height: houseFrameHeight(house))
        .position(x: center.x * size, y: center.y * size)
    }

    private func planetLabel(_ planets: [Planet], isKendra: Bool) -> some View {
        VStack(spacing: 1) {
            ForEach(planetRows(planets, maxPerRow: isKendra ? 4 : 3), id: \.self) { row in
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

    /// Split planets into rows for display
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

    // MARK: - Planet Abbreviations

    private func planetAbbrev(_ planet: Planet) -> String {
        let retro = chart.position(of: planet)?.isRetrograde == true ? "(R)" : ""
        let name: String
        switch planet {
        case .sun:     name = "Su"
        case .moon:    name = "Mo"
        case .mars:    name = "Ma"
        case .mercury: name = "Me"
        case .jupiter: name = "Ju"
        case .venus:   name = "Ve"
        case .saturn:  name = "Sa"
        case .rahu:    name = "Ra"
        case .ketu:    name = "Ke"
        }
        return name + retro
    }

    // MARK: - Geometry — Counter-clockwise house positions

    /// Centroid of each house region in normalized coordinates (0–1).
    ///
    /// North Indian standard: H1 at top, counter-clockwise.
    ///
    ///   Key geometry points (unit square):
    ///     Corners: TL(0,0) TR(1,0) BR(1,1) BL(0,1)
    ///     Side midpoints: T(0.5,0) R(1,0.5) B(0.5,1) L(0,0.5)
    ///     Center: C(0.5,0.5)
    ///     Diamond–diagonal intersections:
    ///       P_TL(0.25,0.25) P_TR(0.75,0.25) P_BR(0.75,0.75) P_BL(0.25,0.75)
    ///
    ///   House regions (counter-clockwise from top):
    ///     H1:  top diamond quad     — T, P_TL, C, P_TR
    ///     H2:  upper-left triangle  — TL, T, P_TL
    ///     H3:  left-upper triangle  — TL, P_TL, L
    ///     H4:  left diamond quad    — L, P_TL, C, P_BL
    ///     H5:  left-lower triangle  — BL, L, P_BL
    ///     H6:  bottom-left triangle — BL, P_BL, B
    ///     H7:  bottom diamond quad  — B, P_BL, C, P_BR
    ///     H8:  bottom-right tri     — BR, B, P_BR
    ///     H9:  right-lower triangle — BR, P_BR, R
    ///     H10: right diamond quad   — R, P_TR, C, P_BR
    ///     H11: right-upper triangle — TR, R, P_TR
    ///     H12: upper-right triangle — TR, P_TR, T
    private func houseCentroid(_ house: Int) -> CGPoint {
        switch house {
        case 1:  return CGPoint(x: 0.50, y: 0.22)   // Top diamond (kendra)
        case 2:  return CGPoint(x: 0.25, y: 0.08)   // Upper-left triangle
        case 3:  return CGPoint(x: 0.08, y: 0.25)   // Left-upper triangle
        case 4:  return CGPoint(x: 0.22, y: 0.50)   // Left diamond (kendra)
        case 5:  return CGPoint(x: 0.08, y: 0.75)   // Left-lower triangle
        case 6:  return CGPoint(x: 0.25, y: 0.92)   // Bottom-left triangle
        case 7:  return CGPoint(x: 0.50, y: 0.78)   // Bottom diamond (kendra)
        case 8:  return CGPoint(x: 0.75, y: 0.92)   // Bottom-right triangle
        case 9:  return CGPoint(x: 0.92, y: 0.75)   // Right-lower triangle
        case 10: return CGPoint(x: 0.78, y: 0.50)   // Right diamond (kendra)
        case 11: return CGPoint(x: 0.92, y: 0.25)   // Right-upper triangle
        case 12: return CGPoint(x: 0.75, y: 0.08)   // Upper-right triangle
        default: return CGPoint(x: 0.50, y: 0.50)
        }
    }

    private func houseFrameWidth(_ house: Int) -> CGFloat {
        let isKendra = [1, 4, 7, 10].contains(house)
        return isKendra ? size * 0.30 : size * 0.20
    }

    private func houseFrameHeight(_ house: Int) -> CGFloat {
        let isKendra = [1, 4, 7, 10].contains(house)
        return isKendra ? size * 0.24 : size * 0.16
    }

    // MARK: - Colors

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

// MARK: - Varga diamond chart (works at any size)

struct NorthIndianVargaChartView: View {
    let vargaChart: VargaChart
    let chart: BirthChart
    let size: CGFloat
    let showFullTitle: Bool

    init(vargaChart: VargaChart, chart: BirthChart, size: CGFloat = 220, showFullTitle: Bool = false) {
        self.vargaChart = vargaChart
        self.chart = chart
        self.size = size
        self.showFullTitle = showFullTitle
    }

    /// Adaptive font sizes based on chart size
    private var signFontSize: CGFloat { max(6, size * 0.022) }
    private var planetFontSize: CGFloat { max(8, size * 0.032) }
    private var titleFont: Font { size >= 300 ? .headline : .caption.bold() }
    private var lineWidth: CGFloat { size >= 300 ? 1.2 : 0.8 }
    private var borderWidth: CGFloat { size >= 300 ? 2.0 : 1.2 }

    var body: some View {
        VStack(spacing: size >= 300 ? 8 : 4) {
            if showFullTitle {
                Text("\(vargaChart.vargaType.shortName) — \(vargaChart.vargaType.name)")
                    .font(titleFont)
            } else {
                Text(vargaChart.vargaType.shortName)
                    .font(titleFont)
            }

            ZStack {
                Rectangle()
                    .fill(Color(nsColor: .controlBackgroundColor))

                chartLines
                    .stroke(Color.primary.opacity(0.5), lineWidth: lineWidth)

                Rectangle()
                    .stroke(Color.primary, lineWidth: borderWidth)

                ForEach(1...12, id: \.self) { house in
                    houseContent(house: house)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Rectangle())
        }
    }

    private var chartLines: Path {
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

    @ViewBuilder
    private func houseContent(house: Int) -> some View {
        let center = houseCentroid(house)
        let lagnaIndex = vargaChart.ascendantSign?.rawValue ?? chart.lagnaSign?.rawValue ?? 0
        let signIndex = (lagnaIndex + house - 1) % 12
        let sign = Sign(rawValue: signIndex)
        let isKendra = [1, 4, 7, 10].contains(house)

        let planetsInSign = vargaChart.placements
            .filter { $0.value.rawValue == signIndex }
            .map { $0.key }

        VStack(spacing: 1) {
            Text(sign.map { "\($0.number)" } ?? "—")
                .font(.system(size: isKendra ? signFontSize + 2 : signFontSize + 1, weight: .bold))
                .foregroundStyle(signColor(sign))

            if !planetsInSign.isEmpty {
                HStack(spacing: 3) {
                    ForEach(planetsInSign, id: \.self) { planet in
                        Text(abbrev(planet))
                            .font(.system(size: planetFontSize, weight: .bold, design: .monospaced))
                            .foregroundStyle(planetColor(planet))
                    }
                }
                .lineLimit(2)
            }
        }
        .frame(width: isKendra ? size * 0.26 : size * 0.18,
               height: isKendra ? size * 0.20 : size * 0.14)
        .position(x: center.x * size, y: center.y * size)
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

    private func abbrev(_ planet: Planet) -> String {
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
}

/// Backward-compatible alias
typealias NorthIndianChartCompactView = NorthIndianVargaChartView
