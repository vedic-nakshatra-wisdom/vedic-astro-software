import Foundation
import SwiftUI
import AstroCore
import CoreLocation

/// Sections available in the sidebar navigation
enum ChartSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case rasiChart = "Rasi Chart (D1)"
    case divisionalCharts = "Divisional Charts"
    case vimshottariDasha = "Vimshottari Dasha"
    case ashtakavarga = "Ashtakavarga"
    case shadbala = "Shadbala"
    case jaimini = "Jaimini System"
    case specialPoints = "Special Points"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.pie"
        case .rasiChart: return "circle.grid.3x3"
        case .divisionalCharts: return "square.grid.4x3.fill"
        case .vimshottariDasha: return "calendar.badge.clock"
        case .ashtakavarga: return "number.square"
        case .shadbala: return "chart.bar"
        case .jaimini: return "person.3"
        case .specialPoints: return "mappin.and.ellipse"
        }
    }
}

/// Location search result
struct LocationResult: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let timeZoneID: String
}

/// Saved chart profile (birth data only)
struct SavedChartProfile: Codable, Identifiable {
    var id: UUID = UUID()
    let name: String
    let year: String
    let month: String
    let day: String
    let hour: String
    let minute: String
    let second: String
    let timeZoneID: String
    let latitude: String
    let longitude: String
    let locationName: String
    let savedDate: Date
}

@Observable
@MainActor
final class ChartViewModel {
    // MARK: - Input Fields
    var name: String = "Swoven Pokharel"
    var year: String = "1985"
    var month: String = "9"
    var day: String = "10"
    var hour: String = "0"
    var minute: String = "45"
    var second: String = "0"
    var timeZoneID: String = "Asia/Kathmandu"
    var latitude: String = "27.7172"
    var longitude: String = "85.3240"

    // MARK: - Location Search
    var locationQuery: String = "Kathmandu, Nepal"
    var locationResults: [LocationResult] = []
    var isSearchingLocation = false
    var selectedLocationName: String = "Kathmandu, Nepal"

    // MARK: - Settings
    var useEightKaraka: Bool = false

    // MARK: - Saved Profiles
    var savedProfiles: [SavedChartProfile] = []
    var showingSavedCharts = false
    var showingSaveBeforeNewAlert = false
    var showingSaveBeforeQuitAlert = false

    // MARK: - Navigation
    var selectedSection: ChartSection? = .dashboard
    var showingInputSheet = false

    // MARK: - State
    var isCalculating = false
    var hasCalculated = false
    var isDirty = false
    var statusMessage = ""
    var errorMessage: String?

    // MARK: - Computed Results
    var chart: BirthChart?
    var vargas: [VargaChart] = []
    var dashaPeriods: [DashaPeriod]?
    var ashtakavarga: AshtakavargaResult?
    var karakas: CharaKarakaResult?
    var shadbala: ShadBalaResult?
    var ishtaDevta: IshtaDevtaResult?
    var arudhaLagna: ArudhaLagnaResult?
    var bhriguBindu: BhriguBinduResult?
    var pushkara: PushkaraResult?
    var chartExport: ChartExport?

    // MARK: - Validation
    var isInputValid: Bool {
        guard !name.isEmpty,
              !timeZoneID.isEmpty,
              TimeZone(identifier: timeZoneID) != nil,
              Int(year) != nil,
              let m = Int(month), (1...12).contains(m),
              let d = Int(day), (1...31).contains(d),
              let h = Int(hour), (0...23).contains(h),
              let min = Int(minute), (0...59).contains(min),
              let sec = Int(second), (0...59).contains(sec),
              Double(latitude) != nil,
              Double(longitude) != nil
        else { return false }
        return true
    }

    // MARK: - Location Search
    func searchLocation() async {
        let query = locationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            locationResults = []
            return
        }

        isSearchingLocation = true
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            locationResults = placemarks.compactMap { pm in
                guard let loc = pm.location,
                      let tz = pm.timeZone else { return nil }
                let placeName = [pm.locality, pm.administrativeArea, pm.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                return LocationResult(
                    name: placeName.isEmpty ? query : placeName,
                    latitude: loc.coordinate.latitude,
                    longitude: loc.coordinate.longitude,
                    timeZoneID: tz.identifier
                )
            }
        } catch {
            locationResults = []
        }

        isSearchingLocation = false
    }

    func selectLocation(_ result: LocationResult) {
        selectedLocationName = result.name
        latitude = String(format: "%.4f", result.latitude)
        longitude = String(format: "%.4f", result.longitude)
        timeZoneID = result.timeZoneID
        locationQuery = result.name
        locationResults = []
    }

    /// Reverse-geocode lat/lon to resolve timezone automatically
    func resolveTimezoneFromCoordinates() async {
        guard let lat = Double(latitude), let lon = Double(longitude) else { return }
        let location = CLLocation(latitude: lat, longitude: lon)
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let tz = placemarks.first?.timeZone {
                timeZoneID = tz.identifier
            }
            if let pm = placemarks.first {
                let placeName = [pm.locality, pm.administrativeArea, pm.country]
                    .compactMap { $0 }
                    .joined(separator: ", ")
                if !placeName.isEmpty {
                    selectedLocationName = placeName
                    locationQuery = placeName
                }
            }
        } catch {
            // Keep existing timezone if reverse geocode fails
        }
    }

    // MARK: - Calculate
    func calculate() async {
        guard isInputValid else {
            errorMessage = "Invalid input. Please check all fields."
            return
        }

        // Extra safety: verify timezone
        guard TimeZone(identifier: timeZoneID) != nil else {
            errorMessage = "Invalid timezone: \(timeZoneID). Use a location search or enter a valid IANA timezone."
            return
        }

        isCalculating = true
        errorMessage = nil
        statusMessage = "Calculating..."

        do {
            let birthData = BirthData.from(
                name: name,
                year: Int(year)!, month: Int(month)!, day: Int(day)!,
                hour: Int(hour)!, minute: Int(minute)!, second: Int(second)!,
                timeZoneID: timeZoneID,
                latitude: Double(latitude)!, longitude: Double(longitude)!
            )

            let ephemeris = EphemerisActor()
            await ephemeris.initialize(ephemerisPath: nil)
            let calc = ChartCalculator(ephemeris: ephemeris)
            let computedChart = await calc.computeChart(for: birthData)

            // Run all calculations
            let allVargas = VargaCalculator().computeAllVargas(from: computedChart)
            let computedVargas = Array(allVargas.values)
            let computedDashas = VimshottariCalculator().computeDashas(from: computedChart)
            let computedAshtakavarga = AshtakavargaCalculator().compute(from: computedChart)
            let computedKarakas = CharaKarakaCalculator().compute(from: computedChart, useEightKaraka: useEightKaraka)
            let computedShadbala = ShadBalaCalculator().compute(from: computedChart)
            let computedArudha = ArudhaLagnaCalculator().compute(from: computedChart)
            let computedBB = BhriguBinduCalculator().compute(from: computedChart, ashtakavarga: computedAshtakavarga)
            let computedPushkara = PushkaraCalculator().compute(from: computedChart)

            var computedIshta: IshtaDevtaResult?
            if let k = computedKarakas {
                computedIshta = IshtaDevtaCalculator().compute(from: computedChart, karakas: k)
            }

            // Build export
            let exporter = ChartExporter()
            let export = exporter.buildExport(
                chart: computedChart,
                vargas: computedVargas,
                dashas: computedDashas,
                ashtakavarga: computedAshtakavarga,
                karakas: computedKarakas,
                shadbala: computedShadbala,
                ishtaDevta: computedIshta,
                arudhaLagna: computedArudha,
                bhriguBindu: computedBB,
                pushkara: computedPushkara
            )

            // Update state
            self.chart = computedChart
            self.vargas = computedVargas
            self.dashaPeriods = computedDashas
            self.ashtakavarga = computedAshtakavarga
            self.karakas = computedKarakas
            self.shadbala = computedShadbala
            self.ishtaDevta = computedIshta
            self.arudhaLagna = computedArudha
            self.bhriguBindu = computedBB
            self.pushkara = computedPushkara
            self.chartExport = export
            self.hasCalculated = true
            self.isDirty = true
            self.statusMessage = "Chart calculated successfully"
            self.showingInputSheet = false

            await ephemeris.close()
        } catch {
            errorMessage = "Calculation failed: \(error.localizedDescription)"
            statusMessage = ""
        }

        isCalculating = false
    }

    // MARK: - Export
    func exportJSON() -> String? {
        guard let export = chartExport else { return nil }
        let exporter = ChartExporter()
        return try? exporter.toJSON(export)
    }

    func exportMarkdown() -> String? {
        guard let export = chartExport else { return nil }
        let exporter = ChartExporter()
        return exporter.toMarkdown(export)
    }

    // MARK: - Recalculate Jaimini (karaka system toggle)
    func recalculateKarakas() {
        guard let chart else { return }
        let newKarakas = CharaKarakaCalculator().compute(from: chart, useEightKaraka: useEightKaraka)
        self.karakas = newKarakas
        if let k = newKarakas {
            self.ishtaDevta = IshtaDevtaCalculator().compute(from: chart, karakas: k)
        } else {
            self.ishtaDevta = nil
        }
    }

    // MARK: - Dasha Helpers
    var currentDashaPath: [DashaPeriod]? {
        guard let dashas = dashaPeriods else { return nil }
        return VimshottariCalculator().activeDashaPath(in: dashas, at: Date())
    }

    // MARK: - Profile Storage

    private static var profilesDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("VedicAstro/Profiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func loadSavedProfiles() {
        let dir = Self.profilesDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter({ $0.pathExtension == "json" }) else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        savedProfiles = files.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(SavedChartProfile.self, from: data)
        }
        .sorted { $0.savedDate > $1.savedDate }
    }

    /// Last directory the user saved a profile to
    private static let lastSaveDirectoryKey = "lastProfileSaveDirectory"

    private static var lastSaveDirectory: URL? {
        get {
            guard let path = UserDefaults.standard.string(forKey: lastSaveDirectoryKey) else { return nil }
            return URL(fileURLWithPath: path)
        }
        set {
            UserDefaults.standard.set(newValue?.path, forKey: lastSaveDirectoryKey)
        }
    }

    private func buildProfileData() -> (SavedChartProfile, Data)? {
        let profile = SavedChartProfile(
            name: name,
            year: year, month: month, day: day,
            hour: hour, minute: minute, second: second,
            timeZoneID: timeZoneID,
            latitude: latitude, longitude: longitude,
            locationName: selectedLocationName,
            savedDate: Date()
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(profile) else { return nil }
        return (profile, data)
    }

    /// Save with file picker — remembers last save location.
    /// `completion` is called after the save completes (or is cancelled).
    /// `didSave` is true if the user actually saved.
    func saveCurrentProfile(askLocation: Bool = true, completion: ((Bool) -> Void)? = nil) {
        guard let (_, data) = buildProfileData() else {
            completion?(false)
            return
        }
        let defaultFilename = "\(name.replacingOccurrences(of: " ", with: "_"))_profile.json"

        #if os(macOS)
        if askLocation {
            let panel = NSSavePanel()
            panel.nameFieldStringValue = defaultFilename
            panel.allowedContentTypes = [.json]
            panel.directoryURL = Self.lastSaveDirectory ?? Self.profilesDirectory
            panel.begin { [weak self] response in
                if response == .OK, let url = panel.url {
                    try? data.write(to: url, options: .atomic)
                    Self.lastSaveDirectory = url.deletingLastPathComponent()
                    let internalURL = Self.profilesDirectory.appendingPathComponent(url.lastPathComponent)
                    if internalURL != url {
                        try? data.write(to: internalURL, options: .atomic)
                    }
                    Task { @MainActor in
                        self?.isDirty = false
                        self?.loadSavedProfiles()
                    }
                    completion?(true)
                } else {
                    completion?(false)
                }
            }
            return
        }
        #endif

        // Silent save (fallback)
        let dir = Self.lastSaveDirectory ?? Self.profilesDirectory
        let url = dir.appendingPathComponent(defaultFilename)
        try? data.write(to: url, options: .atomic)
        let internalURL = Self.profilesDirectory.appendingPathComponent(defaultFilename)
        if internalURL != url {
            try? data.write(to: internalURL, options: .atomic)
        }
        isDirty = false
        loadSavedProfiles()
        completion?(true)
    }

    func loadProfile(_ profile: SavedChartProfile) {
        name = profile.name
        year = profile.year
        month = profile.month
        day = profile.day
        hour = profile.hour
        minute = profile.minute
        second = profile.second
        timeZoneID = profile.timeZoneID
        latitude = profile.latitude
        longitude = profile.longitude
        selectedLocationName = profile.locationName
        locationQuery = profile.locationName
        locationResults = []
        errorMessage = nil
    }

    /// Load a profile from a user-chosen file via open panel.
    func openProfileFromFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.directoryURL = Self.profilesDirectory
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                guard let data = try? Data(contentsOf: url),
                      let profile = try? decoder.decode(SavedChartProfile.self, from: data) else { return }
                Task { @MainActor in
                    self.loadProfile(profile)
                    self.showingInputSheet = true
                }
            }
        }
        #endif
    }

    func deleteProfile(_ profile: SavedChartProfile) {
        let dir = Self.profilesDirectory
        if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            for url in files where url.pathExtension == "json" {
                if let data = try? Data(contentsOf: url),
                   let p = try? decoder.decode(SavedChartProfile.self, from: data),
                   p.id == profile.id {
                    try? FileManager.default.removeItem(at: url)
                    break
                }
            }
        }
        loadSavedProfiles()
    }

    func newChart() {
        // Clear all computed results
        chart = nil
        vargas = []
        dashaPeriods = nil
        ashtakavarga = nil
        karakas = nil
        shadbala = nil
        ishtaDevta = nil
        arudhaLagna = nil
        bhriguBindu = nil
        pushkara = nil
        chartExport = nil
        hasCalculated = false
        statusMessage = ""
        errorMessage = nil

        // Reset input fields
        name = ""
        year = ""
        month = ""
        day = ""
        hour = ""
        minute = ""
        second = ""
        timeZoneID = ""
        latitude = ""
        longitude = ""
        locationQuery = ""
        selectedLocationName = ""
        locationResults = []

        selectedSection = .dashboard
        showingInputSheet = true
    }
}
