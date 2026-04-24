import SwiftUI

struct ProfileRowView: View {
    let profile: SavedChartProfile
    let onLoad: () -> Void
    let onCalculate: () -> Void
    let onToggleFavorite: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(birthSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(profile.locationName)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            if profile.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onToggleFavorite()
            } label: {
                Label(
                    profile.isFavorite ? "Unfavorite" : "Favorite",
                    systemImage: profile.isFavorite ? "star.slash" : "star.fill"
                )
            }
            .tint(.yellow)
        }
        .contextMenu {
            Button {
                onLoad()
            } label: {
                Label("Load & Edit", systemImage: "pencil")
            }
            Button {
                onCalculate()
            } label: {
                Label("Load & Calculate", systemImage: "play.fill")
            }
            Divider()
            Button {
                onToggleFavorite()
            } label: {
                Label(
                    profile.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: profile.isFavorite ? "star.slash" : "star.fill"
                )
            }
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "doc.on.doc")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var birthSummary: String {
        "\(profile.year)-\(profile.month.leftPad(2))-\(profile.day.leftPad(2)) \(profile.hour.leftPad(2)):\(profile.minute.leftPad(2))"
    }
}
