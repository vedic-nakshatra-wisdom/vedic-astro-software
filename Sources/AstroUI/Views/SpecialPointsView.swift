import SwiftUI
import AstroCore

struct SpecialPointsView: View {
    let viewModel: ChartViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let bb = viewModel.bhriguBindu {
                    bhriguBinduSection(bb)
                }

                if let pushkara = viewModel.pushkara {
                    pushkaraSection(pushkara)
                }
            }
            .padding(24)
        }
        .navigationTitle("Special Points")
    }

    // MARK: - Bhrigu Bindu

    private func bhriguBinduSection(_ bb: BhriguBinduResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bhrigu Bindu")
                .font(.headline)
            Text("Midpoint of Moon and Rahu (shorter arc). A sensitive transit trigger point.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 20) {
                // Main position display
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title)
                        .foregroundStyle(.teal)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(bb.formattedPosition)
                            .font(.title2.bold())
                        Text("Longitude: \(String(format: "%.4f", bb.longitude))\u{00B0}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Divider()

                // Detail grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    detailCard("Sign", bb.sign.name, icon: "circle.grid.3x3")
                    detailCard("Degree", String(format: "%.2f", bb.degreeInSign) + "\u{00B0}", icon: "ruler")
                    detailCard("Nakshatra", "\(bb.nakshatra.name) P\(bb.pada)", icon: "star")

                    if let house = bb.house {
                        detailCard("House", "H\(house)", icon: "house")
                    }

                    if let sav = bb.savScore {
                        detailCard("SAV Score", "\(sav)", icon: "number.square",
                                   valueColor: sav >= 28 ? .green : (sav < 25 ? .red : .orange))
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background.secondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.teal.opacity(0.2), lineWidth: 1)
                    )
            )

            // Interpretation note
            VStack(alignment: .leading, spacing: 8) {
                Text("Significance")
                    .font(.subheadline.bold())
                Text("When a transiting planet crosses the Bhrigu Bindu degree, significant events tend to manifest. A higher SAV score at this sign indicates more favorable outcomes during such transits.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Pushkara

    private func pushkaraSection(_ pushkara: PushkaraResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pushkara Analysis")
                .font(.headline)
            Text("Pushkara Navamsa and Pushkara Bhaga indicate auspicious planetary placements that strengthen benefic results.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Full planet table
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    Text("Planet").font(.caption.bold()).frame(width: 80, alignment: .leading)
                    Text("Degree").font(.caption.bold()).frame(width: 70, alignment: .trailing)
                    Text("Navamsa").font(.caption.bold()).frame(width: 90, alignment: .center)
                    Text("P. Navamsa").font(.caption.bold()).frame(width: 90, alignment: .center)
                    Text("PB Deg").font(.caption.bold()).frame(width: 60, alignment: .trailing)
                    Text("Orb").font(.caption.bold()).frame(width: 60, alignment: .trailing)
                    Text("P. Bhaga").font(.caption.bold()).frame(width: 80, alignment: .center)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                ForEach(pushkara.planets, id: \.planet) { info in
                    pushkaraRow(info)
                }
            }
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Summary cards
            HStack(spacing: 12) {
                pushkaraSummaryCard(
                    title: "Pushkara Navamsa",
                    count: pushkara.pushkaraNavamsaPlanets.count,
                    planets: pushkara.pushkaraNavamsaPlanets.map { $0.planet.rawValue },
                    color: .green,
                    icon: "sparkles"
                )
                pushkaraSummaryCard(
                    title: "Pushkara Bhaga",
                    count: pushkara.pushkaraBhagaPlanets.count,
                    planets: pushkara.pushkaraBhagaPlanets.map { $0.planet.rawValue },
                    color: .orange,
                    icon: "target"
                )
            }
        }
    }

    private func pushkaraRow(_ info: PushkaraInfo) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                Circle()
                    .fill(planetColor(info.planet))
                    .frame(width: 8, height: 8)
                Text(info.planet.rawValue)
                    .fontWeight(.medium)
            }
            .frame(width: 80, alignment: .leading)

            Text(String(format: "%.2f", info.degreeInSign) + "\u{00B0}")
                .font(.system(.body, design: .monospaced))
                .frame(width: 70, alignment: .trailing)

            Text(info.navamsaSign.name)
                .font(.caption)
                .frame(width: 90, alignment: .center)

            pushkaraBadge(info.isInPushkaraNavamsa, color: .green)
                .frame(width: 90, alignment: .center)

            Text(String(format: "%.0f", info.pushkaraBhagaDegree) + "\u{00B0}")
                .font(.system(.body, design: .monospaced))
                .frame(width: 60, alignment: .trailing)

            Text(String(format: "%.2f", info.orbFromPushkaraBhaga) + "\u{00B0}")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(info.orbFromPushkaraBhaga <= 1.0 ? .primary : .secondary)
                .frame(width: 60, alignment: .trailing)

            pushkaraBadge(info.isAtPushkaraBhaga, color: .orange)
                .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            (info.isInPushkaraNavamsa || info.isAtPushkaraBhaga)
                ? Color.green.opacity(0.04)
                : Color.clear
        )
    }

    private func pushkaraBadge(_ active: Bool, color: Color) -> some View {
        Text(active ? "Yes" : "No")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(active ? color.opacity(0.15) : Color.clear)
            .foregroundStyle(active ? color : .secondary)
            .clipShape(Capsule())
    }

    private func pushkaraSummaryCard(title: String, count: Int, planets: [String], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.bold())
            }
            if count > 0 {
                Text(planets.joined(separator: ", "))
                    .font(.callout.bold())
            } else {
                Text("None")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.background.secondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(count > 0 ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
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

    // MARK: - Helpers

    private func detailCard(_ title: String, _ value: String, icon: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.bold())
                .foregroundStyle(valueColor)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(.background.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
