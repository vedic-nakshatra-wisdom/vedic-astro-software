import SwiftUI
import AstroCore

struct DashboardView: View {
    let viewModel: ChartViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                // Key Positions — 3-column row
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    if let asc = viewModel.chart?.ascendant {
                        infoCard(title: "Lagna", icon: "sunrise",
                                 content: asc.sign.name, detail: asc.formattedDegree, color: .orange)
                    }
                    if let moon = viewModel.chart?.position(of: .moon) {
                        infoCard(title: "Moon", icon: "moon.fill",
                                 content: moon.sign.name,
                                 detail: "\(moon.nakshatra.name) P\(moon.nakshatraPada)", color: .blue)
                    }
                    if let sun = viewModel.chart?.position(of: .sun) {
                        infoCard(title: "Sun", icon: "sun.max.fill",
                                 content: sun.sign.name, detail: sun.formattedDegree, color: .yellow)
                    }
                }

                // Jaimini & Special — 3-column row
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    if let karakas = viewModel.karakas, let ak = karakas.ranking.first {
                        infoCard(title: "Atmakaraka", icon: "person.fill",
                                 content: ak.planet.rawValue, detail: "Soul significator", color: .indigo)
                    }
                    if let ishta = viewModel.ishtaDevta {
                        infoCard(title: "Ishta Devta", icon: "sparkles",
                                 content: ishta.deity.primary,
                                 detail: "via \(ishta.significator.rawValue)", color: .pink)
                    }
                    if let bb = viewModel.bhriguBindu {
                        infoCard(title: "Bhrigu Bindu", icon: "mappin.and.ellipse",
                                 content: bb.formattedPosition,
                                 detail: bb.savScore.map { "SAV: \($0)" } ?? "", color: .mint)
                    }
                }

                // Current Dasha + Gemstone — side by side
                HStack(alignment: .top, spacing: 12) {
                    if let path = viewModel.currentDashaPath, !path.isEmpty {
                        dashaCard(path: path)
                    }
                    if let gem = viewModel.gemstoneResult {
                        gemstoneCard(gem)
                    }
                }

                // Compatibility Factors
                if let moon = viewModel.chart?.position(of: .moon) {
                    compatibilityCard(moon: moon)
                }

                // Planet positions table
                if let chart = viewModel.chart {
                    planetQuickTable(chart: chart)
                }
            }
            .padding(24)
        }
        .navigationTitle("Dashboard")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.name)
                .font(.largeTitle.bold())
            if let chart = viewModel.chart {
                Text(birthInfo(chart))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func birthInfo(_ chart: BirthChart) -> String {
        let df = DateFormatter()
        df.dateFormat = "d MMMM yyyy, HH:mm"
        df.timeZone = TimeZone(identifier: viewModel.timeZoneID) ?? .current
        return "\(df.string(from: chart.birthData.dateTimeUTC)) (\(viewModel.timeZoneID))"
    }

    // MARK: - Info Card

    private func infoCard(title: String, icon: String, content: String, detail: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(content)
                .font(.title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Dasha Card

    private func dashaCard(path: [DashaPeriod]) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Current Dasha")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    ForEach(Array(path.enumerated()), id: \.offset) { index, period in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(period.planet.rawValue)
                            .font(index == 0 ? .title3.bold() : .subheadline.weight(.medium))
                            .foregroundStyle(index == 0 ? .primary : .secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Until")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(formatted(path.last!.endDate))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.purple)
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Gemstone Card

    private func gemstoneCard(_ gem: GemstoneResult) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "diamond")
                .font(.title2)
                .foregroundStyle(.teal)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Recommended Gemstone")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(gem.gemstone.name)
                        .font(.title3.bold())
                    Text(gem.gemstone.sanskritName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(gem.confidence)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(gem.confidence >= 75 ? .green : gem.confidence >= 50 ? .orange : .red)
                    .clipShape(Capsule())
                Text("for \(gem.recommendedPlanet.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Compatibility Factors

    private func compatibilityCard(moon: PlanetaryPosition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.secondary)
                Text("Compatibility Factors")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                factorRow(icon: "person.3.fill", label: "Gana",
                          value: moon.nakshatra.gana.rawValue.capitalized, color: .mint)
                Divider().padding(.leading, 40)
                factorRow(icon: "pawprint.fill", label: "Yoni",
                          value: "\(moon.nakshatra.yoni.animal.rawValue.capitalized) (\(moon.nakshatra.yoni.gender.rawValue.capitalized))", color: .cyan)
                Divider().padding(.leading, 40)
                factorRow(icon: "waveform.path", label: "Nadi",
                          value: moon.nakshatra.nadi.rawValue.capitalized, color: .green)
                Divider().padding(.leading, 40)
                factorRow(icon: "shield.fill", label: "Varna",
                          value: moon.sign.varna.rawValue.capitalized, color: .brown)
                Divider().padding(.leading, 40)
                factorRow(icon: "hand.raised.fill", label: "Vashya",
                          value: moon.sign.vashya(degreeInSign: moon.degreeInSign).rawValue.capitalized, color: .gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func factorRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline.bold())
                .frame(width: 60, alignment: .leading)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
    }

    // MARK: - Planet Quick Table

    private func planetQuickTable(chart: BirthChart) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planet Positions")
                .font(.headline)

            let order: [Planet] = [.sun, .moon, .mars, .mercury, .jupiter, .venus, .saturn, .rahu, .ketu]

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text("Planet").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Sign").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Degree").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Nakshatra").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("House").font(.caption.bold()).foregroundStyle(.secondary)
                }

                Divider()

                ForEach(order, id: \.self) { planet in
                    if let pos = chart.position(of: planet) {
                        GridRow {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(planetColor(planet))
                                    .frame(width: 8, height: 8)
                                Text(planet.rawValue)
                                    .fontWeight(.medium)
                                if pos.isRetrograde {
                                    Text("R")
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                        .fontWeight(.bold)
                                }
                            }
                            Text(pos.sign.name)
                            Text(pos.formattedDegree)
                                .font(.system(.body, design: .monospaced))
                            Text("\(pos.nakshatra.name) P\(pos.nakshatraPada)")
                                .font(.callout)
                            Text(chart.house(of: planet).map { "H\($0)" } ?? "—")
                                .font(.callout)
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

    private func formatted(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM yyyy"
        return df.string(from: date)
    }

    func planetColor(_ planet: Planet) -> Color {
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
