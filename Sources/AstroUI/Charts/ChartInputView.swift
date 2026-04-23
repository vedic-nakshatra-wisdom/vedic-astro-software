import SwiftUI
import AstroCore

struct ChartInputView: View {
    @State private var name = ""
    @State private var year = "1985"
    @State private var month = "9"
    @State private var day = "10"
    @State private var hour = "0"
    @State private var minute = "45"
    @State private var second = "0"
    @State private var timeZoneID = "Asia/Kathmandu"
    @State private var latitude = "27.7172"
    @State private var longitude = "85.3240"

    @State private var isCalculating = false
    @State private var statusMessage = ""
    @State private var lastExportPath: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("VedicAstro Chart Calculator")
                    .font(.title2.bold())

                GroupBox("Birth Data") {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Name").frame(width: 80, alignment: .trailing)
                            TextField("Full name", text: $name)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack {
                            Text("Date").frame(width: 80, alignment: .trailing)
                            TextField("Year", text: $year)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                            TextField("Month", text: $month)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 55)
                            TextField("Day", text: $day)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 55)
                        }

                        HStack {
                            Text("Time").frame(width: 80, alignment: .trailing)
                            TextField("Hr", text: $hour)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 55)
                            Text(":").frame(width: 8)
                            TextField("Min", text: $minute)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 55)
                            Text(":").frame(width: 8)
                            TextField("Sec", text: $second)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 55)
                        }

                        HStack {
                            Text("Timezone").frame(width: 80, alignment: .trailing)
                            TextField("IANA timezone", text: $timeZoneID)
                                .textFieldStyle(.roundedBorder)
                            #if os(macOS)
                            Text("e.g. Asia/Kathmandu")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            #endif
                        }

                        HStack {
                            Text("Location").frame(width: 80, alignment: .trailing)
                            TextField("Latitude", text: $latitude)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            TextField("Longitude", text: $longitude)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                    }
                    .padding(.vertical, 4)
                }

                HStack {
                    Button(action: calculateAndExport) {
                        if isCalculating {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 4)
                            Text("Calculating...")
                        } else {
                            Text("Calculate & Export JSON")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isCalculating || !isInputValid)

                    Spacer()

                    if let path = lastExportPath {
                        Button("Reveal in Finder") {
                            #if os(macOS)
                            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                            #endif
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if !statusMessage.isEmpty {
                    GroupBox {
                        Text(statusMessage)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
    }

    private var isInputValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && Int(year) != nil && Int(month) != nil && Int(day) != nil
        && Int(hour) != nil && Int(minute) != nil && Int(second) != nil
        && Double(latitude) != nil && Double(longitude) != nil
        && !timeZoneID.isEmpty
    }

    private func calculateAndExport() {
        isCalculating = true
        statusMessage = "Calculating..."

        Task {
            do {
                let json = try await computeFullChart()
                let path = try saveJSON(json)
                await MainActor.run {
                    lastExportPath = path
                    statusMessage = "Exported to:\n\(path)"
                    isCalculating = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Error: \(error.localizedDescription)"
                    isCalculating = false
                }
            }
        }
    }

    private func computeFullChart() async throws -> String {
        let birthData = BirthData.from(
            name: name.trimmingCharacters(in: .whitespaces),
            year: Int(year)!, month: Int(month)!, day: Int(day)!,
            hour: Int(hour)!, minute: Int(minute)!, second: Int(second)!,
            timeZoneID: timeZoneID,
            latitude: Double(latitude)!, longitude: Double(longitude)!
        )

        let eph = EphemerisActor()
        await eph.initialize(ephemerisPath: nil)
        let calc = ChartCalculator(ephemeris: eph)
        let chart = await calc.computeChart(for: birthData)

        // All calculations
        let vargaCalc = VargaCalculator()
        let allVargas = VargaType.allCases.map { vargaCalc.computeVarga($0, from: chart) }

        let dashas = VimshottariCalculator().computeDashas(from: chart)
        let ashtakavarga = AshtakavargaCalculator().compute(from: chart)
        let karakas = CharaKarakaCalculator().compute(from: chart)
        let shadbala = ShadBalaCalculator().compute(from: chart)
        let arudha = ArudhaLagnaCalculator().compute(from: chart)
        let bb = BhriguBinduCalculator().compute(from: chart, ashtakavarga: ashtakavarga)

        var ishtaDevta: IshtaDevtaResult? = nil
        if let k = karakas {
            ishtaDevta = IshtaDevtaCalculator().compute(from: chart, karakas: k)
        }

        let exporter = ChartExporter()
        let export = exporter.buildExport(
            chart: chart,
            vargas: allVargas,
            dashas: dashas,
            ashtakavarga: ashtakavarga,
            karakas: karakas,
            shadbala: shadbala,
            ishtaDevta: ishtaDevta,
            arudhaLagna: arudha,
            bhriguBindu: bb
        )

        await eph.close()
        return try exporter.toJSON(export)
    }

    @MainActor
    private func saveJSON(_ json: String) throws -> String {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.title = "Save Chart JSON"
        panel.nameFieldStringValue = "\(name.replacingOccurrences(of: " ", with: "_"))_chart.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else {
            throw ExportError.cancelled
        }

        try json.write(to: url, atomically: true, encoding: .utf8)
        return url.path
        #else
        // iOS: save to Documents
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "\(name.replacingOccurrences(of: " ", with: "_"))_chart.json"
        let url = docs.appendingPathComponent(fileName)
        try json.write(to: url, atomically: true, encoding: .utf8)
        return url.path
        #endif
    }

    enum ExportError: LocalizedError {
        case cancelled
        var errorDescription: String? { "Export cancelled" }
    }
}
