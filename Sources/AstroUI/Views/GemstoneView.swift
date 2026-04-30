import SwiftUI
import AstroCore

struct GemstoneView: View {
    let viewModel: ChartViewModel

    var body: some View {
        ScrollView {
            if let result = viewModel.gemstoneResult {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero recommendation
                    heroCard(result)

                    // Two-column: Reasoning + Wearing
                    HStack(alignment: .top, spacing: 16) {
                        reasoningSection(result)
                        wearingSection(result)
                    }

                    // Warnings
                    if !result.warnings.isEmpty {
                        warningsSection(result)
                    }

                    // Planet rankings
                    allScoresSection(result)
                }
                .padding(24)
            } else {
                ContentUnavailableView(
                    "No Recommendation",
                    systemImage: "diamond",
                    description: Text("Could not determine a gemstone recommendation for this chart.")
                )
            }
        }
        .navigationTitle("Gemstone")
    }

    // MARK: - Hero Card

    private func heroCard(_ result: GemstoneResult) -> some View {
        ZStack(alignment: .bottomTrailing) {
            // Background gemstone icon watermark
            Image(systemName: "diamond.fill")
                .font(.system(size: 120))
                .foregroundStyle(gemstoneAccent(result.gemstone).opacity(0.08))
                .offset(x: 30, y: 20)

            VStack(alignment: .leading, spacing: 16) {
                // Top: label + confidence
                HStack {
                    Text("RECOMMENDED GEMSTONE")
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    confidenceBadge(result.confidence)
                }

                // Main: gem name + sanskrit
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(result.gemstone.name)
                        .font(.system(size: 34, weight: .bold))
                    Text(result.gemstone.sanskritName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Planet + alternative
                HStack(spacing: 16) {
                    Label(result.recommendedPlanet.rawValue, systemImage: "circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(gemstoneAccent(result.gemstone))

                    if let alt = result.alternativeGemstone {
                        Text("Upratna: \(alt)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(gemstoneAccent(result.gemstone).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(gemstoneAccent(result.gemstone).opacity(0.2), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func confidenceBadge(_ confidence: Int) -> some View {
        HStack(spacing: 4) {
            Text("Confidence")
                .font(.caption2)
            Text("\(confidence)%")
                .font(.subheadline.bold().monospacedDigit())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(confidenceColor(confidence).gradient)
        .clipShape(Capsule())
    }

    private func confidenceColor(_ confidence: Int) -> Color {
        if confidence >= 75 { return .green }
        if confidence >= 50 { return .orange }
        return .red
    }

    private func gemstoneAccent(_ gemstone: Gemstone) -> Color {
        switch gemstone {
        case .ruby: return .red
        case .pearl: return .cyan
        case .redCoral: return .orange
        case .emerald: return .green
        case .yellowSapphire: return .yellow
        case .diamond: return .cyan
        case .blueSapphire: return .blue
        case .hessonite: return .orange
        case .catsEye: return .brown
        }
    }

    // MARK: - Reasoning

    private func reasoningSection(_ result: GemstoneResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Why This Gemstone?", systemImage: "lightbulb.fill")
                .font(.headline)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(result.reasoning.enumerated()), id: \.offset) { index, reason in
                    if index > 0 { Divider().padding(.leading, 32) }
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .frame(width: 20)
                        Text(reason)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Wearing Instructions

    private func wearingSection(_ result: GemstoneResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Wearing Instructions", systemImage: "hand.point.up.left.fill")
                .font(.headline)

            VStack(spacing: 0) {
                wearingRow(icon: "hand.point.up", label: "Finger",
                           value: result.wearingInstructions.finger, color: .blue)
                Divider().padding(.leading, 40)
                wearingRow(icon: "circle.circle", label: "Metal",
                           value: result.wearingInstructions.metal, color: .orange)
                Divider().padding(.leading, 40)
                wearingRow(icon: "calendar", label: "Day",
                           value: result.wearingInstructions.day, color: .purple)
                Divider().padding(.leading, 40)
                wearingRow(icon: "waveform", label: "Mantra",
                           value: result.wearingInstructions.mantra, color: .pink, italic: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func wearingRow(icon: String, label: String, value: String, color: Color, italic: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline.bold())
                .frame(width: 56, alignment: .leading)
            Spacer()
            Group {
                if italic {
                    Text(value).italic()
                } else {
                    Text(value)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 7)
    }

    // MARK: - Warnings

    private func warningsSection(_ result: GemstoneResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.primary)
            ForEach(result.warnings, id: \.self) { warning in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.yellow)
                        .frame(width: 20)
                    Text(warning)
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.yellow.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.yellow.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - All Scores

    private func allScoresSection(_ result: GemstoneResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Planet Rankings", systemImage: "chart.bar.fill")
                .font(.headline)

            VStack(spacing: 2) {
                ForEach(Array(result.allScores.enumerated()), id: \.element.planet) { index, score in
                    scoreRow(score, rank: index + 1, isTop: index == 0 && !score.isDisqualified)
                }
            }
        }
        .padding(16)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func scoreRow(_ score: PlanetGemstoneScore, rank: Int, isTop: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Rank
                Text("\(rank)")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(isTop ? .white : .secondary)
                    .frame(width: 24, height: 24)
                    .background(isTop ? gemstoneAccent(score.gemstone) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(isTop ? .clear : Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                // Planet + gemstone
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(score.planet.rawValue)
                            .font(.subheadline.weight(.semibold))
                        if score.isDisqualified {
                            Text("DISQUALIFIED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(.red.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 4) {
                        Text(score.gemstone.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let reason = score.disqualifyReason {
                            Text("- \(reason)")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                }

                Spacer()

                // Score bar + value
                HStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.quaternary)
                            .frame(width: 120, height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(score.isDisqualified ? AnyShapeStyle(.gray) : scoreBarGradient(score.totalScore))
                            .frame(width: max(0, 120 * score.totalScore / 100.0), height: 8)
                    }
                    Text(String(format: "%.1f", score.totalScore))
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(isTop ? gemstoneAccent(score.gemstone) : .secondary)
                        .frame(width: 36, alignment: .trailing)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(isTop ? gemstoneAccent(score.gemstone).opacity(0.05) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func scoreBarGradient(_ score: Double) -> AnyShapeStyle {
        if score >= 50 { return AnyShapeStyle(.green.gradient) }
        if score >= 30 { return AnyShapeStyle(.orange.gradient) }
        return AnyShapeStyle(.red.opacity(0.6).gradient)
    }
}
