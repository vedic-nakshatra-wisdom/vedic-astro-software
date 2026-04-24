import SwiftUI
import AstroCore

struct AshtakavargaView: View {
    let viewModel: ChartViewModel

    private let planetOrder: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let ashtaka = viewModel.ashtakavarga {
                    // SAV Summary
                    savSummarySection(ashtaka.sarvashtakavarga)

                    // BAV Heatmap Grid
                    bavGridSection(ashtaka)

                    // SAV Detail
                    savDetailSection(ashtaka.sarvashtakavarga)
                }
            }
            .padding(24)
        }
        .navigationTitle("Ashtakavarga")
    }

    // MARK: - SAV Summary

    private func savSummarySection(_ sav: Sarvashtakavarga) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sarvashtakavarga Summary")
                .font(.headline)

            Text("Total: \(sav.total) (expected: 337)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // SAV bar chart per sign
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Sign.allCases, id: \.self) { sign in
                    let value = sav.bindus[sign.rawValue]
                    let maxVal = 40.0

                    VStack(spacing: 4) {
                        Text("\(value)")
                            .font(.caption2.bold())
                            .foregroundStyle(value >= 28 ? .green : (value < 25 ? .red : .primary))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(binduColor(value, max: 40))
                            .frame(width: 28, height: CGFloat(value) / maxVal * 100)

                        Text(sign.shortName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 160)
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - BAV Grid

    private func bavGridSection(_ ashtaka: AshtakavargaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bhinnashtakavarga (BAV)")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                    // Header row with sign abbreviations
                    GridRow {
                        Text("")
                            .frame(width: 60)
                        ForEach(Sign.allCases, id: \.self) { sign in
                            Text(sign.shortName)
                                .font(.caption2.bold())
                                .frame(width: 36)
                                .foregroundStyle(.secondary)
                        }
                        Text("Total")
                            .font(.caption2.bold())
                            .frame(width: 40)
                            .foregroundStyle(.secondary)
                    }

                    // Planet rows
                    ForEach(planetOrder, id: \.self) { planet in
                        if let bav = ashtaka.bpiBindus[planet] {
                            GridRow {
                                Text(planet.rawValue)
                                    .font(.caption.bold())
                                    .frame(width: 60, alignment: .leading)

                                ForEach(0..<12, id: \.self) { i in
                                    let value = bav.bindus[i]
                                    Text("\(value)")
                                        .font(.system(.caption, design: .monospaced))
                                        .frame(width: 36, height: 28)
                                        .background(cellColor(value, max: 8))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }

                                Text("\(bav.total)")
                                    .font(.caption.bold())
                                    .frame(width: 40)
                            }
                        }
                    }

                    Divider()

                    // SAV row
                    GridRow {
                        Text("SAV")
                            .font(.caption.bold())
                            .frame(width: 60, alignment: .leading)

                        ForEach(0..<12, id: \.self) { i in
                            let value = ashtaka.sarvashtakavarga.bindus[i]
                            Text("\(value)")
                                .font(.system(.caption, design: .monospaced).bold())
                                .frame(width: 36, height: 28)
                                .background(binduColor(value, max: 40))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Text("\(ashtaka.sarvashtakavarga.total)")
                            .font(.caption.bold())
                            .frame(width: 40)
                    }
                }
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - SAV Detail

    private func savDetailSection(_ sav: Sarvashtakavarga) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SAV Sign Strength")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(Sign.allCases, id: \.self) { sign in
                    let value = sav.bindus[sign.rawValue]
                    let strength = value >= 28 ? "Strong" : (value < 25 ? "Weak" : "Average")

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(sign.name)
                                .font(.caption.bold())
                            Text("\(value) bindus")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(strength)
                            .font(.caption2)
                            .foregroundStyle(value >= 28 ? .green : (value < 25 ? .red : .orange))
                    }
                    .padding(8)
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Helpers

    private func cellColor(_ value: Int, max: Int) -> Color {
        let ratio = Double(value) / Double(max)
        if ratio >= 0.6 { return .green.opacity(0.2) }
        if ratio >= 0.4 { return .yellow.opacity(0.15) }
        return .red.opacity(0.1)
    }

    private func binduColor(_ value: Int, max: Int) -> Color {
        let ratio = Double(value) / Double(max)
        if ratio >= 0.7 { return .green.opacity(0.3) }
        if ratio >= 0.55 { return .yellow.opacity(0.2) }
        return .red.opacity(0.15)
    }
}
