import SwiftUI
import AstroCore

struct ShadbalaView: View {
    let viewModel: ChartViewModel

    private let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let shadbala = viewModel.shadbala {
                    overviewChart(shadbala)
                    relativeStrengthSection(shadbala)
                    detailedBreakdown(shadbala)
                    subBalaCards(shadbala)
                    ishtaKashtaSection(shadbala)
                }
            }
            .padding(24)
        }
        .navigationTitle("Shadbala")
    }

    // MARK: - Overview Chart

    private func overviewChart(_ shadbala: ShadBalaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Strength (Rupas)")
                .font(.headline)
            Text("Minimum requirements shown as dashed lines")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(planetOrder, id: \.self) { planet in
                    if let bala = shadbala.planetBala[planet] {
                        let minRupas = ShadBalaResult.minimumRupas[planet] ?? 5.0
                        let maxRupas = max(10.0, bala.totalRupas + 1.0)

                        VStack(spacing: 6) {
                            Text(String(format: "%.1f", bala.totalRupas))
                                .font(.caption.bold())
                                .foregroundStyle(bala.totalRupas >= minRupas ? .green : .red)

                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.gray.opacity(0.1))
                                    .frame(width: 40, height: 140)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(planetColor(planet).opacity(0.7))
                                    .frame(
                                        width: 40,
                                        height: min(CGFloat(bala.totalRupas) / maxRupas * 140, 140)
                                    )

                                Rectangle()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4]))
                                    .foregroundStyle(.red.opacity(0.6))
                                    .frame(width: 46, height: 1)
                                    .offset(y: -(CGFloat(minRupas) / maxRupas * 140))
                            }
                            .frame(height: 140)

                            Text(planet.rawValue)
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Detailed Breakdown

    private func detailedBreakdown(_ shadbala: ShadBalaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Breakdown (Virupas)")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                    GridRow {
                        headerCell("Planet", width: 70, align: .leading)
                        headerCell("Sthana")
                        headerCell("Dig")
                        headerCell("Kala")
                        headerCell("Cheshta")
                        headerCell("Naisar.")
                        headerCell("Drik")
                        headerCell("Total", width: 60)
                        headerCell("Rupas")
                    }

                    Divider()

                    ForEach(planetOrder, id: \.self) { planet in
                        if let b = shadbala.planetBala[planet] {
                            let minRupas = ShadBalaResult.minimumRupas[planet] ?? 5.0
                            GridRow {
                                HStack(spacing: 4) {
                                    Circle().fill(planetColor(planet)).frame(width: 8, height: 8)
                                    Text(planet.rawValue).font(.caption.bold())
                                }
                                .frame(width: 70, alignment: .leading)

                                balaCell(b.sthanaBala, max: 300)
                                balaCell(b.digBala, max: 60)
                                balaCell(b.kalaBala, max: 300)
                                balaCell(b.cheshtaBala, max: 60)
                                balaCell(b.naisargikaBala, max: 60)
                                drikCell(b.drikBala)

                                Text(String(format: "%.0f", b.totalVirupas))
                                    .font(.system(.caption, design: .monospaced).bold())
                                    .frame(width: 60)

                                Text(String(format: "%.2f", b.totalRupas))
                                    .font(.system(.caption, design: .monospaced).bold())
                                    .foregroundStyle(b.totalRupas >= minRupas ? .green : .red)
                                    .frame(width: 50)
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

    // MARK: - Sub-bala Cards

    private func subBalaCards(_ shadbala: ShadBalaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strength Categories")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                strengthCard("Sthana Bala", subtitle: "Positional", keyPath: \.sthanaBala, shadbala: shadbala)
                strengthCard("Dig Bala", subtitle: "Directional", keyPath: \.digBala, shadbala: shadbala)
                strengthCard("Kala Bala", subtitle: "Temporal", keyPath: \.kalaBala, shadbala: shadbala)
                strengthCard("Cheshta Bala", subtitle: "Motional", keyPath: \.cheshtaBala, shadbala: shadbala)
                strengthCard("Drik Bala", subtitle: "Aspectual", keyPath: \.drikBala, shadbala: shadbala)
                strengthCard("Naisargika", subtitle: "Natural", keyPath: \.naisargikaBala, shadbala: shadbala)
            }
        }
    }

    // MARK: - Ishta / Kashta Phala

    private func ishtaKashtaSection(_ shadbala: ShadBalaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ishta & Kashta Phala")
                .font(.headline)
            Text("Benefic vs difficult potential for each planet's Dasha")
                .font(.caption)
                .foregroundStyle(.secondary)

            Grid(horizontalSpacing: 8, verticalSpacing: 6) {
                GridRow {
                    headerCell("Planet", width: 70, align: .leading)
                    headerCell("Ishta")
                    headerCell("Kashta")
                    headerCell("Net")
                }

                Divider()

                ForEach(planetOrder, id: \.self) { planet in
                    if let b = shadbala.planetBala[planet] {
                        GridRow {
                            HStack(spacing: 4) {
                                Circle().fill(planetColor(planet)).frame(width: 8, height: 8)
                                Text(planet.rawValue).font(.caption.bold())
                            }
                            .frame(width: 70, alignment: .leading)

                            Text(String(format: "%.1f", b.ishtaPhala))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.green)
                                .frame(width: 50)

                            Text(String(format: "%.1f", b.kashtaPhala))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.red)
                                .frame(width: 50)

                            Text(String(format: "%.1f", b.ishtaPhala - b.kashtaPhala))
                                .font(.system(.caption, design: .monospaced).bold())
                                .foregroundStyle(b.ishtaPhala >= b.kashtaPhala ? .green : .red)
                                .frame(width: 50)
                        }
                    }
                }
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Relative Strength (Ratio above minimum)

    private func relativeStrengthSection(_ shadbala: ShadBalaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relative Strength (Ratio above Minimum)")
                .font(.headline)
            Text("Planets ranked by how far they exceed their minimum requirement — the true measure of functional strength")
                .font(.caption)
                .foregroundStyle(.secondary)

            let ranked = planetOrder.compactMap { planet -> (Planet, Double, Double, Double)? in
                guard let bala = shadbala.planetBala[planet],
                      let minR = ShadBalaResult.minimumRupas[planet] else { return nil }
                let ratio = bala.totalRupas / minR
                return (planet, bala.totalRupas, minR, ratio)
            }.sorted { $0.3 > $1.3 }

            let maxRatio = ranked.first?.3 ?? 1.0

            ForEach(Array(ranked.enumerated()), id: \.offset) { index, item in
                let (planet, rupas, minR, ratio) = item
                let meetsMin = rupas >= minR

                HStack(spacing: 12) {
                    Text("#\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: 24)

                    Circle()
                        .fill(planetColor(planet))
                        .frame(width: 10, height: 10)

                    Text(planet.rawValue)
                        .font(.caption.bold())
                        .frame(width: 60, alignment: .leading)

                    // Ratio bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.gray.opacity(0.1))
                                .frame(width: geo.size.width)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(meetsMin ? planetColor(planet).opacity(0.6) : .red.opacity(0.4))
                                .frame(width: max(4, CGFloat(ratio / maxRatio) * geo.size.width))

                            // 1.0 ratio marker (= minimum met exactly)
                            Rectangle()
                                .fill(.red.opacity(0.5))
                                .frame(width: 1.5, height: geo.size.height)
                                .offset(x: CGFloat(1.0 / maxRatio) * geo.size.width)
                        }
                    }
                    .frame(height: 20)

                    Text(String(format: "%.2f×", ratio))
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(meetsMin ? .green : .red)
                        .frame(width: 50, alignment: .trailing)

                    Text(String(format: "%.1f / %.1f", rupas, minR))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(index == 0 ? planetColor(planet).opacity(0.05) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func strengthCard(_ title: String, subtitle: String, keyPath: KeyPath<PlanetShadBala, Double>, shadbala: ShadBalaResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.bold())
            Text(subtitle).font(.caption2).foregroundStyle(.secondary)

            ForEach(planetOrder, id: \.self) { planet in
                if let bala = shadbala.planetBala[planet] {
                    HStack(spacing: 4) {
                        Circle().fill(planetColor(planet)).frame(width: 6, height: 6)
                        Text(planet.rawValue).font(.caption2).frame(width: 50, alignment: .leading)
                        Spacer()
                        Text(String(format: "%.1f", bala[keyPath: keyPath]))
                            .font(.system(.caption2, design: .monospaced))
                    }
                }
            }
        }
        .padding(12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func headerCell(_ text: String, width: CGFloat = 50, align: HorizontalAlignment = .center) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: align == .leading ? .leading : .center)
    }

    private func balaCell(_ value: Double, max: Double) -> some View {
        let ratio = value / max
        return Text(String(format: "%.1f", value))
            .font(.system(.caption, design: .monospaced))
            .frame(width: 50)
            .background(
                ratio >= 0.6 ? Color.green.opacity(0.1) :
                ratio >= 0.3 ? Color.yellow.opacity(0.08) :
                Color.red.opacity(0.06)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func drikCell(_ value: Double) -> some View {
        Text(String(format: "%.1f", value))
            .font(.system(.caption, design: .monospaced))
            .frame(width: 50)
            .background(value >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func planetColor(_ planet: Planet) -> Color {
        switch planet {
        case .sun: return .orange
        case .moon: return .blue
        case .mars: return .red
        case .mercury: return .green
        case .jupiter: return .yellow
        case .venus: return .pink
        case .saturn: return .gray
        case .rahu: return .indigo
        case .ketu: return .brown
        }
    }
}
