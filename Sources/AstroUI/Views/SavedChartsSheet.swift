import SwiftUI
import AstroCore

struct SavedChartsSheet: View {
    @Bindable var viewModel: ChartViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Saved Charts")
                    .font(.title2.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            if viewModel.savedProfiles.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Saved Charts")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("Calculate a chart and tap Save to store it here.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.savedProfiles) { profile in
                            profileRow(profile)
                        }
                    }
                    .padding(16)
                }
            }

            Divider()

            // Footer
            HStack {
                Text("\(viewModel.savedProfiles.count) saved chart(s)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding(16)
        }
        .frame(width: 520, height: 450)
    }

    private func profileRow(_ profile: SavedChartProfile) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.body.bold())
                Text(birthSummary(profile))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(profile.locationName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Saved date
            Text(profile.savedDate, style: .date)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            // Load button
            Button {
                viewModel.loadProfile(profile)
                dismiss()
                viewModel.showingInputSheet = true
            } label: {
                Label("Load", systemImage: "arrow.down.circle")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            // Load & Calculate
            Button {
                viewModel.loadProfile(profile)
                dismiss()
                Task { await viewModel.calculate() }
            } label: {
                Label("Calculate", systemImage: "play.fill")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            // Delete
            Button {
                viewModel.deleteProfile(profile)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func birthSummary(_ profile: SavedChartProfile) -> String {
        "\(profile.year)-\(profile.month.leftPad(2))-\(profile.day.leftPad(2)) \(profile.hour.leftPad(2)):\(profile.minute.leftPad(2)):\(profile.second.leftPad(2)) (\(profile.timeZoneID))"
    }
}

private extension String {
    func leftPad(_ length: Int, with char: Character = "0") -> String {
        if count >= length { return self }
        return String(repeating: char, count: length - count) + self
    }
}
