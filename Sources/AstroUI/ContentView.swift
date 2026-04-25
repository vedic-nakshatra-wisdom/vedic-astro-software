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
        .confirmationDialog(
            "Delete Chart",
            isPresented: $viewModel.showDeleteConfirmation,
            presenting: viewModel.profileToDelete
        ) { profile in
            Button("Delete \"\(profile.name)\"", role: .destructive) {
                viewModel.deleteProfile(profile)
                viewModel.profileToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                viewModel.profileToDelete = nil
            }
        } message: { profile in
            Text("Are you sure you want to delete \"\(profile.name)\"? This cannot be undone.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveBeforeQuit)) { _ in
            if viewModel.isDirty {
                viewModel.showingSaveBeforeQuitAlert = true
            } else {
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
            // --- Profile Sections ---
            if !viewModel.favoriteProfiles.isEmpty {
                Section("Favorites") {
                    ForEach(viewModel.favoriteProfiles) { profile in
                        profileRow(profile)
                            .tag(SidebarSelection.profile(profile.id))
                    }
                }
            }

            if !viewModel.recentProfiles.isEmpty {
                Section("Recent") {
                    ForEach(viewModel.recentProfiles) { profile in
                        profileRow(profile)
                            .tag(SidebarSelection.profile(profile.id))
                    }
                }
            }

            Section("All Charts") {
                ForEach(viewModel.filteredProfiles) { profile in
                    profileRow(profile)
                        .tag(SidebarSelection.profile(profile.id))
                }
            }

            // --- Chart Analysis Sections ---
            if viewModel.hasCalculated {
                Section("Chart Analysis") {
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
                    .padding(.vertical, 4)
                    .listRowSeparator(.hidden)

                    ForEach(ChartSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.icon)
                            .tag(SidebarSelection.section(section))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $viewModel.searchText, prompt: "Search charts...")
        .navigationTitle("VedicAstro")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if viewModel.isDirty {
                        viewModel.showingSaveBeforeNewAlert = true
                    } else {
                        viewModel.newChart()
                    }
                } label: {
                    Label("New Chart", systemImage: "plus.circle")
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Picker("Sort By", selection: $viewModel.sortOrder) {
                        ForEach(ProfileSortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                if viewModel.hasCalculated {
                    Button {
                        viewModel.showingInputSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Button {
                        viewModel.openProfileFromFile()
                    } label: {
                        Label("Open from File...", systemImage: "doc.badge.arrow.up")
                    }

                    Divider()

                    if viewModel.hasCalculated {
                        Button {
                            viewModel.saveCurrentProfile()
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }

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
                    }
                } label: {
                    Label("File", systemImage: "doc")
                }
            }
        }
        .onChange(of: viewModel.selectedSection) { _, newValue in
            if case .profile(let id) = newValue {
                if let profile = viewModel.savedProfiles.first(where: { $0.id == id }) {
                    viewModel.loadProfile(profile)
                    viewModel.updateLastOpened(profile)
                    Task {
                        await viewModel.calculate()
                        viewModel.selectedSection = .section(.dashboard)
                    }
                }
            }
        }
    }

    // MARK: - Profile Row

    private func profileRow(_ profile: SavedChartProfile) -> some View {
        ProfileRowView(
            profile: profile,
            onLoad: {
                viewModel.loadProfile(profile)
                viewModel.updateLastOpened(profile)
                viewModel.showingInputSheet = true
            },
            onCalculate: {
                viewModel.loadProfile(profile)
                viewModel.updateLastOpened(profile)
                Task { await viewModel.calculate() }
            },
            onToggleFavorite: {
                viewModel.toggleFavorite(profile)
            },
            onDuplicate: {
                viewModel.duplicateProfile(profile)
            },
            onDelete: {
                viewModel.profileToDelete = profile
                viewModel.showDeleteConfirmation = true
            }
        )
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
                case .section(let section):
                    chartAnalysisView(for: section)
                case .profile, .none:
                    chartAnalysisView(for: .dashboard)
                }
            }
        }
    }

    @ViewBuilder
    private func chartAnalysisView(for section: ChartSection) -> some View {
        switch section {
        case .dashboard:
            DashboardView(viewModel: viewModel)
        case .rasiChart:
            RasiChartView(viewModel: viewModel)
        case .bhavaChalit:
            BhavaChalitView(viewModel: viewModel)
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
        case .transits:
            TransitView(viewModel: viewModel)
        case .specialPoints:
            SpecialPointsView(viewModel: viewModel)
        }
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        ContentUnavailableView {
            Label("VedicAstro", systemImage: "sparkles")
                .font(.largeTitle)
        } description: {
            Text("Vedic Astrology Chart Calculator")
        } actions: {
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
        }
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
