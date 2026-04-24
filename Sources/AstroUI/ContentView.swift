import SwiftUI
import AstroCore
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var viewModel = ChartViewModel()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1000, minHeight: 700)
        .sheet(isPresented: $viewModel.showingInputSheet) {
            BirthDataFormView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingSavedCharts) {
            SavedChartsSheet(viewModel: viewModel)
        }
        .alert("Save Current Chart?", isPresented: $viewModel.showingSaveBeforeNewAlert) {
            Button("Save & New Chart") {
                viewModel.saveCurrentProfile(askLocation: true) { didSave in
                    if didSave {
                        Task { @MainActor in viewModel.newChart() }
                    }
                }
            }
            Button("Don't Save", role: .destructive) {
                viewModel.newChart()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to save \"\(viewModel.name)\" before starting a new chart?")
        }
        .alert("Save Before Quitting?", isPresented: $viewModel.showingSaveBeforeQuitAlert) {
            Button("Save & Quit") {
                viewModel.saveCurrentProfile(askLocation: true) { didSave in
                    if didSave {
                        NotificationCenter.default.post(name: .forceQuitAllowed, object: nil)
                        DispatchQueue.main.async { NSApp.terminate(nil) }
                    }
                }
            }
            Button("Save Only") {
                viewModel.saveCurrentProfile(askLocation: true)
            }
            Button("Quit Without Saving", role: .destructive) {
                NotificationCenter.default.post(name: .forceQuitAllowed, object: nil)
                DispatchQueue.main.async { NSApp.terminate(nil) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Do you want to save \"\(viewModel.name)\" before quitting?")
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveBeforeQuit)) { _ in
            if viewModel.isDirty {
                viewModel.showingSaveBeforeQuitAlert = true
            } else {
                // No chart to save — just quit
                NotificationCenter.default.post(name: .forceQuitAllowed, object: nil)
                NSApp.terminate(nil)
            }
        }
        .onAppear {
            viewModel.loadSavedProfiles()
            if !viewModel.hasCalculated {
                viewModel.showingInputSheet = true
            }
        }
    }

    // MARK: - Sidebar

    @ViewBuilder
    private var sidebar: some View {
        List(selection: $viewModel.selectedSection) {
            if viewModel.hasCalculated {
                // Summary header
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.name)
                        .font(.headline)
                    if let lagna = viewModel.chart?.lagnaSign {
                        Text("\(lagna.name) Lagna")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(viewModel.selectedLocationName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)

                Section("Chart Analysis") {
                    ForEach(ChartSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.icon)
                            .tag(section)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("VedicAstro")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // New Chart
                Button {
                    if viewModel.isDirty {
                        viewModel.showingSaveBeforeNewAlert = true
                    } else {
                        viewModel.newChart()
                    }
                } label: {
                    Label("New Chart", systemImage: "plus.circle")
                }

                // Edit current
                if viewModel.hasCalculated {
                    Button {
                        viewModel.showingInputSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                }

                // Saved Charts
                Menu {
                    Button {
                        viewModel.loadSavedProfiles()
                        viewModel.showingSavedCharts = true
                    } label: {
                        Label("Saved Charts", systemImage: "folder")
                    }
                    Button {
                        viewModel.openProfileFromFile()
                    } label: {
                        Label("Open from File...", systemImage: "doc.badge.arrow.up")
                    }
                } label: {
                    Label("Saved", systemImage: "folder")
                }

                // Save current profile
                if viewModel.hasCalculated {
                    Button {
                        viewModel.saveCurrentProfile()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }

                // Export
                if viewModel.hasCalculated {
                    Menu {
                        Button {
                            saveFile(type: "json")
                        } label: {
                            Label("Export JSON", systemImage: "doc.text")
                        }
                        Button {
                            saveFile(type: "md")
                        } label: {
                            Label("Export Markdown", systemImage: "doc.richtext")
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        if viewModel.isCalculating {
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                Text("Computing chart...")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !viewModel.hasCalculated {
            welcomeView
        } else {
            Group {
                switch viewModel.selectedSection {
                case .dashboard:
                    DashboardView(viewModel: viewModel)
                case .rasiChart:
                    RasiChartView(viewModel: viewModel)
                case .divisionalCharts:
                    DivisionalChartsView(viewModel: viewModel)
                case .vimshottariDasha:
                    DashaView(viewModel: viewModel)
                case .ashtakavarga:
                    AshtakavargaView(viewModel: viewModel)
                case .shadbala:
                    ShadbalaView(viewModel: viewModel)
                case .jaimini:
                    JaiminiView(viewModel: viewModel)
                case .specialPoints:
                    SpecialPointsView(viewModel: viewModel)
                case .none:
                    DashboardView(viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(
                    colors: [.orange, .pink, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("VedicAstro")
                .font(.largeTitle.bold())

            Text("Vedic Astrology Chart Calculator")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button {
                viewModel.showingInputSheet = true
            } label: {
                Label("Create Chart", systemImage: "plus.circle.fill")
                    .font(.title3)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Export

    private func saveFile(type: String) {
        let content: String?
        let defaultName: String
        if type == "json" {
            content = viewModel.exportJSON()
            defaultName = "\(viewModel.name.replacingOccurrences(of: " ", with: "_"))_chart.json"
        } else {
            content = viewModel.exportMarkdown()
            defaultName = "\(viewModel.name.replacingOccurrences(of: " ", with: "_"))_chart.md"
        }
        guard let content else { return }

        #if os(macOS)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = type == "json" ? [.json] : [.plainText]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? content.write(to: url, atomically: true, encoding: .utf8)
                if type == "json" {
                    let schemaURL = url.deletingLastPathComponent().appendingPathComponent("chart_schema.json")
                    try? ChartSchemaProvider.schemaJSON.write(to: schemaURL, atomically: true, encoding: .utf8)
                }
            }
        }
        #endif
    }
}
