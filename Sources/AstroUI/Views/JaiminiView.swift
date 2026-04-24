import SwiftUI
import AstroCore

struct JaiminiView: View {
    @Bindable var viewModel: ChartViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Karaka system toggle
                karakaSystemToggle

                // Chara Karakas
                if let karakas = viewModel.karakas {
                    karakasSection(karakas)
                }

                // Karakamsa & Ishta Devta
                if let ishta = viewModel.ishtaDevta {
                    karakamsaSection(ishta)
                    ishtaDevtaSection(ishta)
                }

                // Arudha Lagnas
                if let arudha = viewModel.arudhaLagna {
                    arudhaSection(arudha)
                }
            }
            .padding(24)
        }
        .navigationTitle("Jaimini System")
    }

    // MARK: - Karaka System Toggle

    private var karakaSystemToggle: some View {
        HStack {
            Text("Karaka System")
                .font(.subheadline.bold())
            Spacer()
            Picker("", selection: $viewModel.useEightKaraka) {
                Text("7-Karaka (KN Rao)").tag(false)
                Text("8-Karaka (incl. Rahu)").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)
            .onChange(of: viewModel.useEightKaraka) {
                viewModel.recalculateKarakas()
            }
        }
        .padding(12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Chara Karakas

    private func karakasSection(_ karakas: CharaKarakaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chara Karakas")
                    .font(.headline)
                Spacer()
                Text(karakas.isEightKaraka ? "8-Karaka System" : "7-Karaka System")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.blue.opacity(0.1)))
            }

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("Karaka").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Abbreviation").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Planet").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Degree").font(.caption.bold()).foregroundStyle(.secondary)
                }

                Divider()

                ForEach(Array(karakas.ranking.enumerated()), id: \.offset) { _, entry in
                    GridRow {
                        Text(entry.karaka.rawValue)
                            .fontWeight(.medium)
                        Text(entry.karaka.abbreviation)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Circle()
                                .fill(planetColor(entry.planet))
                                .frame(width: 8, height: 8)
                            Text(entry.planet.rawValue)
                                .fontWeight(.semibold)
                        }
                        Text(String(format: "%.2f", entry.degreeInSign) + "\u{00B0}")
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Karakamsa

    private func karakamsaSection(_ ishta: IshtaDevtaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Karakamsa")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 24) {
                    labeledValue("Atmakaraka", ishta.atmakaraka.rawValue)
                    labeledValue("AK in Navamsa (D9)", ishta.karakamsa.karakamsaSign.name)
                    if let h = ishta.karakamsa.houseFromLagna {
                        labeledValue("House from Lagna", "H\(h)")
                    }
                }

                if !ishta.karakamsa.planetsInKarakamsa.isEmpty {
                    HStack(spacing: 8) {
                        Text("Planets in Karakamsa:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(ishta.karakamsa.planetsInKarakamsa, id: \.self) { planet in
                            Text(planet.rawValue)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(planetColor(planet).opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(16)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Ishta Devta

    private func ishtaDevtaSection(_ ishta: IshtaDevtaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ishta Devta (Chosen Deity)")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                // Main deity display
                HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(.yellow)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(ishta.deity.primary)
                            .font(.title2.bold())
                        Text(ishta.deity.theme)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Details
                VStack(alignment: .leading, spacing: 8) {
                    detailRow("12th from Karakamsa", ishta.twelfthSign.name)

                    if !ishta.planetsInTwelfth.isEmpty {
                        detailRow("Planets in 12th", ishta.planetsInTwelfth.map { $0.rawValue }.joined(separator: ", "))
                    } else {
                        detailRow("Planets in 12th", "None (sign lord used)")
                    }

                    detailRow("Significator", ishta.significator.rawValue)
                }

                // Alternate deities
                if !ishta.deity.alternates.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alternate Deities")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(ishta.deity.alternates, id: \.self) { alt in
                                Text(alt)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.purple.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.background.secondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.yellow.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Arudha Lagnas

    private func arudhaSection(_ arudha: ArudhaLagnaResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Arudha Lagnas (12 Padas)")
                .font(.headline)

            let columns = Array(repeating: GridItem(.flexible()), count: 4)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array<Int>(1...12), id: \.self) { house in
                    arudhaCell(house: house, arudha: arudha)
                }
            }
        }
    }

    private func arudhaCell(house: Int, arudha: ArudhaLagnaResult) -> some View {
        let labels: [Int: String] = [
            1: "AL (Pada Lagna)", 2: "A2 (Dhana)", 3: "A3 (Vikrama)",
            4: "A4 (Matri)", 5: "A5 (Mantra)", 6: "A6 (Roga)",
            7: "A7 (Dara)", 8: "A8 (Mrityu)", 9: "A9 (Dharma)",
            10: "A10 (Rajya)", 11: "A11 (Labha)", 12: "UL (Upapada)"
        ]
        let sign = arudha.arudha(ofHouse: house)
        let isKey = house == 1 || house == 7 || house == 12
        let bg: Color = isKey ? Color.blue.opacity(0.06) : Color(nsColor: .controlBackgroundColor)

        return VStack(alignment: .leading, spacing: 4) {
            Text(labels[house] ?? "A\(house)")
                .font(.caption.bold())
                .foregroundStyle(isKey ? .blue : .primary)
            Text(sign?.name ?? "—")
                .font(.body.bold())
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func labeledValue(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.body.bold())
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout.bold())
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
