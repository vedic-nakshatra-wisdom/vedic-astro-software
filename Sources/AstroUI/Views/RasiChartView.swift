import SwiftUI
import AstroCore

struct RasiChartView: View {
    let viewModel: ChartViewModel

    private let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // D1 and D9 Diamond Charts side by side
                if let chart = viewModel.chart {
                    let d9 = viewModel.vargas.first(where: { $0.vargaType == .d9 })

                    HStack(alignment: .top, spacing: 16) {
                        NorthIndianChartView(chart: chart, title: "Rasi (D1)", size: 320)
                        if let d9 {
                            NorthIndianVargaChartView(vargaChart: d9, chart: chart, size: 320, showFullTitle: true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                }

                // Ascendant
                if let asc = viewModel.chart?.ascendant {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ascendant (Lagna)")
                            .font(.headline)
                        HStack(spacing: 20) {
                            labeledValue("Sign", asc.sign.name)
                            labeledValue("Degree", asc.formattedDegree)
                            labeledValue("Nakshatra", "\(asc.nakshatra.name) Pada \(asc.nakshatraPada)")
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Planet positions table
                if let chart = viewModel.chart {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Planet Positions")
                            .font(.headline)

                        // Use a table-like Grid
                        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                            // Header
                            GridRow {
                                Text("Planet").font(.caption.bold()).foregroundStyle(.secondary)
                                    .gridColumnAlignment(.leading)
                                Text("Sign").font(.caption.bold()).foregroundStyle(.secondary)
                                Text("Longitude").font(.caption.bold()).foregroundStyle(.secondary)
                                Text("Degree").font(.caption.bold()).foregroundStyle(.secondary)
                                Text("Nakshatra").font(.caption.bold()).foregroundStyle(.secondary)
                                Text("Pada").font(.caption.bold()).foregroundStyle(.secondary)
                                Text("House").font(.caption.bold()).foregroundStyle(.secondary)
                                Text("Retro").font(.caption.bold()).foregroundStyle(.secondary)
                            }

                            Divider()

                            ForEach(planetOrder, id: \.self) { planet in
                                if let pos = chart.position(of: planet) {
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
                                        Text(String(format: "%.4f", pos.longitude) + "\u{00B0}")
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                        Text(pos.formattedDegree)
                                            .font(.system(.body, design: .monospaced))
                                        Text(pos.nakshatra.name)
                                        Text("\(pos.nakshatraPada)")
                                            .frame(width: 30, alignment: .center)
                                        Text(chart.house(of: planet).map { "H\($0)" } ?? "—")
                                            .frame(width: 30, alignment: .center)
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
            }
            .padding(24)
        }
        .navigationTitle("Rasi Chart (D1)")
    }

    // MARK: - Helpers

    private func labeledValue(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.bold())
        }
    }

    private func signColor(_ sign: Sign) -> Color {
        switch sign.element {
        case .fire:  return .red
        case .earth: return .brown
        case .air:   return .teal
        case .water: return .blue
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

// MARK: - Flow Layout (for wrapping planet tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
