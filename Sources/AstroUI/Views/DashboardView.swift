import SwiftUI
import AstroCore

struct DashboardView: View {
    let viewModel: ChartViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with name and basic info
                headerSection

                // Quick overview cards in a grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    // Card 1: Ascendant info
                    if let asc = viewModel.chart?.ascendant {
                        infoCard(
                            title: "Ascendant (Lagna)",
                            icon: "sunrise",
                            content: asc.sign.name,
                            detail: asc.formattedDegree,
                            color: .orange
                        )
                    }

                    // Card 2: Moon sign
                    if let moon = viewModel.chart?.position(of: .moon) {
                        infoCard(
                            title: "Moon Sign (Rasi)",
                            icon: "moon.fill",
                            content: moon.sign.name,
                            detail: "\(moon.nakshatra.name) Pada \(moon.nakshatraPada)",
                            color: .blue
                        )
                    }

                    // Card 3: Sun sign
                    if let sun = viewModel.chart?.position(of: .sun) {
                        infoCard(
                            title: "Sun Sign",
                            icon: "sun.max.fill",
                            content: sun.sign.name,
                            detail: sun.formattedDegree,
                            color: .yellow
                        )
                    }

                    // Card 4: Current Dasha
                    if let path = viewModel.currentDashaPath, !path.isEmpty {
                        let dashaStr = path.map { $0.planet.rawValue }.joined(separator: " / ")
                        infoCard(
                            title: "Current Dasha",
                            icon: "calendar.badge.clock",
                            content: dashaStr,
                            detail: "Until \(formatted(path.last!.endDate))",
                            color: .purple
                        )
                    }

                    // Card 5: Atmakaraka
                    if let karakas = viewModel.karakas {
                        let ak = karakas.ranking.first
                        infoCard(
                            title: "Atmakaraka",
                            icon: "person.fill",
                            content: ak?.planet.rawValue ?? "—",
                            detail: "Soul significator",
                            color: .indigo
                        )
                    }

                    // Card 6: Ishta Devta
                    if let ishta = viewModel.ishtaDevta {
                        infoCard(
                            title: "Ishta Devta",
                            icon: "sparkles",
                            content: ishta.deity.primary,
                            detail: "via \(ishta.significator.rawValue)",
                            color: .pink
                        )
                    }

                    // Card 7: Bhrigu Bindu
                    if let bb = viewModel.bhriguBindu {
                        infoCard(
                            title: "Bhrigu Bindu",
                            icon: "mappin.and.ellipse",
                            content: bb.formattedPosition,
                            detail: bb.savScore.map { "SAV: \($0)" } ?? "",
                            color: .teal
                        )
                    }
                }

                // Planet positions quick table
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
                let df = DateFormatter()
                // This is a computed property inline for display
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
