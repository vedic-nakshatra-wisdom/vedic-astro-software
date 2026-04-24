import SwiftUI
import AstroCore

struct ShadbalaView: View {
    let viewModel: ChartViewModel

    private let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let shadbala = viewModel.shadbala {
                    // Overview bar chart
                    overviewChart(shadbala)

                    // Detailed breakdown table
                    detailedBreakdown(shadbala)

                    // Sub-bala comparison
                    subBalaCards(shadbala)
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
                        let maxRupas = 10.0

                        VStack(spacing: 6) {
                            Text(String(format: "%.1f", bala.totalRupas))
                                .font(.caption.bold())
                                .foregroundStyle(bala.totalRupas >= minRupas ? .green : .red)

                            ZStack(alignment: .bottom) {
                                // Background
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.gray.opacity(0.1))
                                    .frame(width: 40, height: 140)

                                // Bar
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(planetColor(planet).opacity(0.7))
                                    .frame(
                                        width: 40,
                                        height: min(CGFloat(bala.totalRupas) / maxRupas * 140, 140)
                                    )

                                // Minimum line
                                Rectangle()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [4]))
                                    .foregroundStyle(.red.opacity(0.5))
                                    .frame(width: 40, height: 1)
                                    .offset(y: -(CGFloat(minRupas) / maxRupas * 140 - 70))
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
                Grid(horizontalSpacing: 8, verticalSpacing: 6) {
                    // Header
                    GridRow {
                        Text("Planet").font(.caption.bold()).foregroundStyle(.secondary)
                            .frame(width: 70, alignment: .leading)
                        Text("Uchcha").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
                        Text("SaptaV").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
                        Text("OjhaY").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
                        Text("Kendra").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
                        Text("Drekk").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
                        Text("Dig").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
                        Text("Naisarg").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
                        Text("Paksha").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
                        Text("Total").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 65)
                        Text("Rupas").font(.caption.bold()).foregroundStyle(.secondary).frame(width: 55)
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

                                balaCell(b.uchchaBala, max: 60)
                                balaCell(b.saptavargajaBala, max: 45)
                                balaCell(b.ojhayugmarasiBala, max: 30)
                                balaCell(b.kendradiBala, max: 60)
                                balaCell(b.drekkanaBala, max: 15)
                                balaCell(b.digBala, max: 60)
                                balaCell(b.naisargikaBala, max: 60)
                                balaCell(b.pakshaBala, max: 60)

                                Text(String(format: "%.1f", b.totalVirupas))
                                    .font(.system(.caption, design: .monospaced).bold())
                                    .frame(width: 65)

                                Text(String(format: "%.2f", b.totalRupas))
                                    .font(.system(.caption, design: .monospaced).bold())
                                    .foregroundStyle(b.totalRupas >= minRupas ? .green : .red)
                                    .frame(width: 55)
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
            }
        }
    }

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

    // MARK: - Helpers

    private func balaCell(_ value: Double, max: Double) -> some View {
        let ratio = value / max
        return Text(String(format: "%.1f", value))
            .font(.system(.caption, design: .monospaced))
            .frame(width: 55)
            .background(
                ratio >= 0.6 ? Color.green.opacity(0.1) :
                ratio >= 0.3 ? Color.yellow.opacity(0.08) :
                Color.red.opacity(0.06)
            )
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
