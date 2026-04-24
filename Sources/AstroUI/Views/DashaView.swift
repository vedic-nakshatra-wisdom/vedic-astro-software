import SwiftUI
import AstroCore

struct DashaView: View {
    let viewModel: ChartViewModel
    @State private var expandedMaha: Planet?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Current period highlight
                if let path = viewModel.currentDashaPath, !path.isEmpty {
                    currentPeriodCard(path)
                }

                // Maha Dasha timeline
                if let dashas = viewModel.dashaPeriods {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Maha Dasha Timeline")
                            .font(.headline)

                        ForEach(Array(dashas.enumerated()), id: \.offset) { index, maha in
                            mahaDashaRow(maha, isActive: isActive(maha))
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Vimshottari Dasha")
    }

    // MARK: - Current Period Card

    private func currentPeriodCard(_ path: [DashaPeriod]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Period")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(Array(path.enumerated()), id: \.offset) { index, period in
                    VStack(spacing: 4) {
                        Text(["Maha", "Antar", "Pratyantar"][min(index, 2)])
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(period.planet.rawValue)
                            .font(.title3.bold())
                            .foregroundStyle(planetColor(period.planet))
                        Text("\(formatted(period.startDate)) — \(formatted(period.endDate))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if index < path.count - 1 {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.blue.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Maha Dasha Row

    private func mahaDashaRow(_ maha: DashaPeriod, isActive: Bool) -> some View {
        VStack(spacing: 0) {
            // Main row — clickable
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedMaha = expandedMaha == maha.planet ? nil : maha.planet
                }
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(planetColor(maha.planet))
                        .frame(width: 12, height: 12)

                    Text(maha.planet.rawValue)
                        .font(.body.bold())
                        .frame(width: 70, alignment: .leading)

                    // Duration bar
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(planetColor(maha.planet).opacity(isActive ? 0.5 : 0.2))
                            .frame(width: geo.size.width)
                    }
                    .frame(height: 24)

                    Text(formatted(maha.startDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 75, alignment: .trailing)
                    Text("—")
                        .foregroundStyle(.tertiary)
                    Text(formatted(maha.endDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 75, alignment: .leading)

                    Image(systemName: expandedMaha == maha.planet ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isActive ? planetColor(maha.planet).opacity(0.05) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            // Expanded antar dashas
            if expandedMaha == maha.planet && !maha.subPeriods.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(maha.subPeriods.enumerated()), id: \.offset) { _, antar in
                        HStack(spacing: 12) {
                            Spacer().frame(width: 24)
                            Circle()
                                .fill(planetColor(antar.planet))
                                .frame(width: 6, height: 6)
                            Text(antar.planet.rawValue)
                                .font(.caption)
                                .frame(width: 60, alignment: .leading)
                            Spacer()
                            Text(formatted(antar.startDate))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(formatted(antar.endDate))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                        .background(isAntarActive(antar) ? planetColor(antar.planet).opacity(0.05) : .clear)
                    }
                }
                .padding(.bottom, 8)
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func isActive(_ period: DashaPeriod) -> Bool {
        let now = Date()
        return period.startDate <= now && now <= period.endDate
    }

    private func isAntarActive(_ period: DashaPeriod) -> Bool {
        guard let path = viewModel.currentDashaPath, path.count > 1 else { return false }
        let now = Date()
        return period.startDate <= now && now <= period.endDate
    }

    private func formatted(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.timeZone = TimeZone(identifier: "UTC")
        return df.string(from: date)
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
