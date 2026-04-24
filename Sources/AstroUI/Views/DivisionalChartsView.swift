import SwiftUI
import AstroCore

struct DivisionalChartsView: View {
    let viewModel: ChartViewModel

    private let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Shodasha Varga (16 Divisional Charts)")
                    .font(.headline)

                if !viewModel.vargas.isEmpty, let chart = viewModel.chart {
                    // Master grid (text table)
                    masterGrid

                    // Diamond charts grid
                    diamondChartsGrid(chart: chart)
                }
            }
            .padding(24)
        }
        .navigationTitle("Divisional Charts")
    }

    // MARK: - Diamond Charts Grid

    private func diamondChartsGrid(chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Charts")
                .font(.subheadline.bold())

            let sorted = viewModel.vargas
                .filter { $0.vargaType != .d1 } // D1 already shown on Rasi page
                .sorted { $0.vargaType.rawValue < $1.vargaType.rawValue }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(sorted, id: \.vargaType) { varga in
                    NorthIndianVargaChartView(
                        vargaChart: varga,
                        chart: chart,
                        size: 220,
                        showFullTitle: true
                    )
                }
            }
        }
    }

    // MARK: - Master Grid

    private var masterGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Vargas at a Glance")
                .font(.subheadline.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                let sorted = viewModel.vargas.sorted { $0.vargaType.rawValue < $1.vargaType.rawValue }

                Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                    // Header: Varga names
                    GridRow {
                        Text("Planet")
                            .font(.caption.bold())
                            .frame(width: 70, alignment: .leading)
                            .foregroundStyle(.secondary)

                        ForEach(sorted, id: \.vargaType) { varga in
                            Text(varga.vargaType.shortName)
                                .font(.caption2.bold())
                                .frame(width: 42)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Lagna row
                    GridRow {
                        Text("Lagna")
                            .font(.caption.bold())
                            .frame(width: 70, alignment: .leading)

                        ForEach(sorted, id: \.vargaType) { varga in
                            Text(varga.ascendantSign?.shortName ?? "—")
                                .font(.system(.caption2, design: .monospaced))
                                .frame(width: 42, height: 24)
                                .background(.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }

                    Divider()

                    // Planet rows
                    ForEach(planetOrder, id: \.self) { planet in
                        GridRow {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(planetColor(planet))
                                    .frame(width: 6, height: 6)
                                Text(planet.rawValue)
                                    .font(.caption)
                            }
                            .frame(width: 70, alignment: .leading)

                            ForEach(sorted, id: \.vargaType) { varga in
                                let sign = varga.placements[planet]
                                Text(sign?.shortName ?? "—")
                                    .font(.system(.caption2, design: .monospaced))
                                    .frame(width: 42, height: 24)
                                    .background(signBackground(sign))
                                    .clipShape(RoundedRectangle(cornerRadius: 3))
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

    private func signBackground(_ sign: Sign?) -> Color {
        guard let sign else { return .clear }
        switch sign.element {
        case .fire: return .red.opacity(0.08)
        case .earth: return .green.opacity(0.08)
        case .air: return .blue.opacity(0.08)
        case .water: return .cyan.opacity(0.08)
        }
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
