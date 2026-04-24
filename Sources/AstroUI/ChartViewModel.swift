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
    var isFavorite: Bool = false
    var lastOpenedDate: Date?

    init(id: UUID = UUID(), name: String, year: String, month: String, day: String,
         hour: String, minute: String, second: String, timeZoneID: String,
         latitude: String, longitude: String, locationName: String, savedDate: Date,
         isFavorite: Bool = false, lastOpenedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.minute = minute
        self.second = second
        self.timeZoneID = timeZoneID
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.savedDate = savedDate
        self.isFavorite = isFavorite
        self.lastOpenedDate = lastOpenedDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        year = try container.decode(String.self, forKey: .year)
        month = try container.decode(String.self, forKey: .month)
        day = try container.decode(String.self, forKey: .day)
        hour = try container.decode(String.self, forKey: .hour)
        minute = try container.decode(String.self, forKey: .minute)
        second = try container.decode(String.self, forKey: .second)
        timeZoneID = try container.decode(String.self, forKey: .timeZoneID)
        latitude = try container.decode(String.self, forKey: .latitude)
        longitude = try container.decode(String.self, forKey: .longitude)
        locationName = try container.decode(String.self, forKey: .locationName)
        savedDate = try container.decode(Date.self, forKey: .savedDate)
        isFavorite = (try? container.decode(Bool.self, forKey: .isFavorite)) ?? false
        lastOpenedDate = try? container.decode(Date.self, forKey: .lastOpenedDate)
    }
}

/// Sort order for saved profiles
enum ProfileSortOrder: String, CaseIterable, Identifiable {
    case dateCreated = "Date Created"
    case name = "Name"
    case birthDate = "Birth Date"

    var id: String { rawValue }
}

/// Unified sidebar selection
enum SidebarSelection: Hashable {
    case profile(UUID)
    case section(ChartSection)
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
    var showingSaveBeforeNewAlert = false
    var showingSaveBeforeQuitAlert = false
    var searchText: String = ""
    var sortOrder: ProfileSortOrder = .dateCreated
    var profileToDelete: SavedChartProfile?
    var showDeleteConfirmation = false

    // MARK: - Navigation
    var selectedSection: SidebarSelection? = .section(.dashboard)
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

    // MARK: - Computed Profile Lists

    var favoriteProfiles: [SavedChartProfile] {
        savedProfiles.filter(\.isFavorite).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var recentProfiles: [SavedChartProfile] {
        savedProfiles
            .filter { $0.lastOpenedDate != nil }
            .sorted { ($0.lastOpenedDate ?? .distantPast) > ($1.lastOpenedDate ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    var filteredProfiles: [SavedChartProfile] {
        let base: [SavedChartProfile]
        if searchText.isEmpty {
            base = savedProfiles
        } else {
            let query = searchText.lowercased()
            base = savedProfiles.filter {
                $0.name.lowercased().contains(query) ||
                $0.locationName.lowercased().contains(query)
            }
        }
        switch sortOrder {
        case .dateCreated:
            return base.sorted { $0.savedDate > $1.savedDate }
        case .name:
            return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .birthDate:
            return base.sorted {
                let a = "\($0.year)-\($0.month.leftPad(2))-\($0.day.leftPad(2))"
                let b = "\($1.year)-\($1.month.leftPad(2))-\($1.day.leftPad(2))"
                return a < b
            }
        }
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
        let fm = FileManager.default
        savedProfiles = files.compactMap { url in
            guard let data = try? Data(contentsOf: url),
                  let profile = try? decoder.decode(SavedChartProfile.self, from: data) else { return nil }
            // Migrate to UUID-based filename if needed
            let expectedName = "\(profile.id.uuidString).json"
            if url.lastPathComponent != expectedName {
                let newURL = dir.appendingPathComponent(expectedName)
                try? fm.moveItem(at: url, to: newURL)
            }
            return profile
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
        guard let (profile, data) = buildProfileData() else {
            completion?(false)
            return
        }
        let defaultFilename = "\(name.replacingOccurrences(of: " ", with: "_"))_profile.json"
        let internalFilename = "\(profile.id.uuidString).json"

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
                    let internalURL = Self.profilesDirectory.appendingPathComponent(internalFilename)
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
        let internalURL = Self.profilesDirectory.appendingPathComponent(internalFilename)
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
        let url = dir.appendingPathComponent("\(profile.id.uuidString).json")
        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        } else {
            // Fallback: scan files for old naming convention
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                for fileURL in files where fileURL.pathExtension == "json" {
                    if let data = try? Data(contentsOf: fileURL),
                       let p = try? decoder.decode(SavedChartProfile.self, from: data),
                       p.id == profile.id {
                        try? FileManager.default.removeItem(at: fileURL)
                        break
                    }
                }
            }
        }
        loadSavedProfiles()
    }

    func toggleFavorite(_ profile: SavedChartProfile) {
        let dir = Self.profilesDirectory
        let url = dir.appendingPathComponent("\(profile.id.uuidString).json")
        guard let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard var updated = try? decoder.decode(SavedChartProfile.self, from: data) else { return }
        updated.isFavorite.toggle()
        writeProfile(updated, to: url)
        loadSavedProfiles()
    }

    func duplicateProfile(_ profile: SavedChartProfile) {
        let newProfile = SavedChartProfile(
            name: "\(profile.name) (Copy)",
            year: profile.year, month: profile.month, day: profile.day,
            hour: profile.hour, minute: profile.minute, second: profile.second,
            timeZoneID: profile.timeZoneID,
            latitude: profile.latitude, longitude: profile.longitude,
            locationName: profile.locationName,
            savedDate: Date()
        )
        let dir = Self.profilesDirectory
        let url = dir.appendingPathComponent("\(newProfile.id.uuidString).json")
        writeProfile(newProfile, to: url)
        loadSavedProfiles()
    }

    func updateLastOpened(_ profile: SavedChartProfile) {
        let dir = Self.profilesDirectory
        let url = dir.appendingPathComponent("\(profile.id.uuidString).json")
        guard let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard var updated = try? decoder.decode(SavedChartProfile.self, from: data) else { return }
        updated.lastOpenedDate = Date()
        writeProfile(updated, to: url)
        loadSavedProfiles()
    }

    private func writeProfile(_ profile: SavedChartProfile, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(profile) else { return }
        try? data.write(to: url, options: .atomic)
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

        selectedSection = .section(.dashboard)
        showingInputSheet = true
    }
}

extension String {
    func leftPad(_ length: Int, with char: Character = "0") -> String {
        if count >= length { return self }
        return String(repeating: char, count: length - count) + self
    }
}
