import SwiftUI
import AstroCore

struct BirthDataFormView: View {
    @Bindable var viewModel: ChartViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Birth Details")
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

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name
                    formSection("Person") {
                        LabeledContent("Name") {
                            TextField("Full name", text: $viewModel.name)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 300)
                        }
                    }

                    // Date of Birth
                    formSection("Date of Birth") {
                        HStack(spacing: 12) {
                            LabeledContent("Year") {
                                TextField("YYYY", text: $viewModel.year)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                            }
                            LabeledContent("Month") {
                                TextField("MM", text: $viewModel.month)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                            LabeledContent("Day") {
                                TextField("DD", text: $viewModel.day)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                        }
                    }

                    // Time of Birth
                    formSection("Time of Birth (Local)") {
                        HStack(spacing: 12) {
                            LabeledContent("Hour") {
                                TextField("HH", text: $viewModel.hour)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                            LabeledContent("Minute") {
                                TextField("MM", text: $viewModel.minute)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                            LabeledContent("Second") {
                                TextField("SS", text: $viewModel.second)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 60)
                            }
                        }
                        Text("Use 24-hour format (0-23)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Location with search
                    formSection("Birth Place") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("Search city or place...", text: $viewModel.locationQuery)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit {
                                        Task { await viewModel.searchLocation() }
                                    }

                                Button {
                                    Task { await viewModel.searchLocation() }
                                } label: {
                                    if viewModel.isSearchingLocation {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                }
                                .disabled(viewModel.locationQuery.isEmpty)
                            }

                            // Search results dropdown
                            if !viewModel.locationResults.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.locationResults) { result in
                                        Button {
                                            viewModel.selectLocation(result)
                                        } label: {
                                            HStack {
                                                Image(systemName: "mappin")
                                                    .foregroundStyle(.red)
                                                    .frame(width: 20)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(result.name)
                                                        .font(.body)
                                                    Text("\(String(format: "%.4f", result.latitude)), \(String(format: "%.4f", result.longitude)) (\(result.timeZoneID))")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                            }
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        if result.id != viewModel.locationResults.last?.id {
                                            Divider()
                                        }
                                    }
                                }
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                            }

                            // Coordinates (editable) — timezone auto-resolves
                            HStack(spacing: 16) {
                                LabeledContent("Latitude") {
                                    TextField("Lat", text: $viewModel.latitude)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                        .onSubmit {
                                            Task { await viewModel.resolveTimezoneFromCoordinates() }
                                        }
                                }
                                LabeledContent("Longitude") {
                                    TextField("Lon", text: $viewModel.longitude)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                        .onSubmit {
                                            Task { await viewModel.resolveTimezoneFromCoordinates() }
                                        }
                                }
                            }
                            .font(.caption)

                            // Timezone (auto-resolved from location)
                            HStack(spacing: 6) {
                                Image(systemName: "clock.badge.checkmark")
                                    .foregroundStyle(.green)
                                Text("Timezone:")
                                    .foregroundStyle(.secondary)
                                Text(viewModel.timeZoneID)
                                    .fontWeight(.medium)
                                if TimeZone(identifier: viewModel.timeZoneID) == nil && !viewModel.timeZoneID.isEmpty {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .font(.caption)
                        }
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(24)
            }

            Divider()

            // Footer buttons
            HStack {
                if viewModel.hasCalculated {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                }

                Spacer()

                Button {
                    Task { await viewModel.calculate() }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isCalculating {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(viewModel.hasCalculated ? "Recalculate" : "Calculate Chart")
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.isInputValid || viewModel.isCalculating)
                .keyboardShortcut(.return)
            }
            .padding(20)
        }
        .frame(width: 600, height: 580)
    }

    // MARK: - Section Helper

    private func formSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            content()
        }
    }
}
