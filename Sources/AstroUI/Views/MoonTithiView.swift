import SwiftUI
import AstroCore

struct MoonTithiView: View {
    let viewModel: ChartViewModel
    @State private var displayYear: Int = Calendar.current.component(.year, from: Date())
    @State private var displayMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var isLoading = false
    @State private var monthData: MonthTithiData?
    @State private var selectedDay: DayTithiInfo?

    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                monthNavigationHeader
                weekdayHeader
                calendarGrid

                if let day = selectedDay {
                    dayDetailPanel(day)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(24)
        }
        .navigationTitle("Moon Tithi")
        .task {
            await loadMonth()
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationHeader: some View {
        HStack {
            Button {
                goToPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(monthData?.monthName ?? monthYearString)
                    .font(.title2.bold())
                Text("Tithi Calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    let now = Date()
                    displayYear = Calendar.current.component(.year, from: now)
                    displayMonth = Calendar.current.component(.month, from: now)
                    Task { await loadMonth() }
                } label: {
                    Text("Today")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    goToNextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.bold())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: gridColumns, spacing: 0) {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Calendar Grid

    @ViewBuilder
    private var calendarGrid: some View {
        if isLoading {
            VStack(spacing: 12) {
                ProgressView()
                Text("Computing tithi data...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 400)
        } else if let data = monthData {
            let emptyCells = (data.firstWeekday - 1)

            LazyVGrid(columns: gridColumns, spacing: 4) {
                ForEach(0..<emptyCells, id: \.self) { _ in
                    Color.clear
                        .frame(height: 110)
                }

                ForEach(data.days, id: \.dayOfMonth) { dayInfo in
                    dayCell(dayInfo)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedDay?.dayOfMonth == dayInfo.dayOfMonth {
                                    selectedDay = nil
                                } else {
                                    selectedDay = dayInfo
                                }
                            }
                        }
                }
            }
        } else {
            ContentUnavailableView(
                "No Data",
                systemImage: "moon",
                description: Text("Could not compute tithi data for this month.")
            )
        }
    }

    // MARK: - Day Cell

    private func dayCell(_ info: DayTithiInfo) -> some View {
        let isToday = isCurrentDay(info)
        let isSelected = selectedDay?.dayOfMonth == info.dayOfMonth
        let isShukla = info.tithi.paksha == .shukla

        return VStack(alignment: .leading, spacing: 3) {
            // Row 1: Date + Tithi day badge
            HStack {
                Text("\(info.dayOfMonth)")
                    .font(.system(size: 13, weight: isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 22, height: 22)
                    .background(isToday ? .blue : .clear)
                    .clipShape(Circle())

                Spacer()

                Text("\(info.tithi.tithiDay)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(isShukla ? Color.yellow.opacity(0.8) : Color.indigo.opacity(0.8))
                    .clipShape(Circle())
            }

            // Row 2: Moon phase icon
            HStack {
                Spacer()
                Image(systemName: info.tithi.moonPhaseIcon)
                    .font(.system(size: 18))
                    .foregroundStyle(isShukla ? .yellow : .indigo)
                Spacer()
            }

            // Row 3: Tithi name
            Text(info.tithi.name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isShukla ? .orange : .purple)
                .lineLimit(1)

            // Row 4: Transition time label
            if let endDate = info.tithiEndDate {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(.tertiary)
                    Text(tithiTimeFormatter.string(from: endDate))
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }

            // Row 5: Moon Rashi (Sanskrit)
            Text(info.moonSignSanskrit)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.teal)
                .lineLimit(1)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 110)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(cellBackground(info, isToday: isToday))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? .blue :
                    isToday ? .blue.opacity(0.5) :
                    isPurnima(info) ? .yellow.opacity(0.3) :
                    isAmavasya(info) ? .indigo.opacity(0.3) :
                    .clear,
                    lineWidth: isSelected ? 2.5 : isToday ? 2 : 1
                )
        )
        .contentShape(Rectangle())
    }

    // MARK: - Day Detail Panel

    private func dayDetailPanel(_ info: DayTithiInfo) -> some View {
        let isShukla = info.tithi.paksha == .shukla
        let tz = TimeZone(identifier: viewModel.timeZoneID) ?? .current

        return VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 16) {
                // Moon phase icon large
                Image(systemName: info.tithi.moonPhaseIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(isShukla ? .yellow : .indigo)
                    .frame(width: 56)

                VStack(alignment: .leading, spacing: 4) {
                    // Date
                    Text(dayDetailDateString(info, timeZone: tz))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Tithi name
                    HStack(spacing: 8) {
                        Text(info.tithi.name)
                            .font(.title2.bold())
                        Text(info.tithi.paksha.displayName)
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isShukla ? .yellow.opacity(0.15) : .indigo.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    // Deity
                    HStack(spacing: 4) {
                        Text("Deity:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(info.tithi.deity)
                            .font(.caption.bold())
                    }
                }

                Spacer()

                // Progress ring
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(.gray.opacity(0.2), lineWidth: 5)
                            .frame(width: 52, height: 52)
                        Circle()
                            .trim(from: 0, to: info.tithiProgress)
                            .stroke(
                                isShukla ? Color.yellow : Color.indigo,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 52, height: 52)
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.0f%%", info.tithiProgress * 100))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                    }
                    Text("tithi elapsed")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                // Close button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedDay = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Detail grid
            HStack(alignment: .top, spacing: 0) {
                // Column 1: Tithi & Transition
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(icon: "moon.stars", label: "Tithi", value: "\(info.tithi.paksha.displayName) \(info.tithi.name)", color: isShukla ? .yellow : .indigo)

                    if let endDate = info.tithiEndDate {
                        let timeFmt = {
                            let f = DateFormatter()
                            f.dateFormat = "h:mm a"
                            f.timeZone = tz
                            return f
                        }()
                        let dayFmt = {
                            let f = DateFormatter()
                            f.dateFormat = "d MMM"
                            f.timeZone = tz
                            return f
                        }()
                        detailRow(icon: "clock", label: "Ends at", value: "\(timeFmt.string(from: endDate)), \(dayFmt.string(from: endDate))", color: .orange)
                        detailRow(icon: "arrow.right", label: "Then", value: info.nextTithi.name, color: .purple)
                    }

                    detailRow(icon: "sparkle", label: "Deity", value: info.tithi.deity, color: .pink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .padding(.horizontal, 12)

                // Column 2: Moon & Panchanga
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(icon: "moon.fill", label: "Moon Rashi", value: "\(info.moonSign.name) (\(info.moonSignSanskrit))", color: .blue)
                    detailRow(icon: "star.fill", label: "Nakshatra", value: info.moonNakshatra, color: .cyan)
                    detailRow(icon: "sun.max.fill", label: "Sun Rashi", value: "\(info.sunSign.name) (\(info.sunSign.sanskritName))", color: .orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .padding(.horizontal, 12)

                // Column 3: Karana, Yoga, Angle
                VStack(alignment: .leading, spacing: 10) {
                    detailRow(icon: "square.split.2x1", label: "Karana", value: info.karana, color: .green)
                    detailRow(icon: "waveform.path", label: "Yoga", value: info.yoga, color: .mint)
                    detailRow(icon: "angle", label: "Sun-Moon", value: String(format: "%.2f\u{00B0}", info.sunMoonAngle), color: .gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.background.secondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isShukla ? .yellow.opacity(0.15) : .indigo.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 18)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.bold())
            }
        }
    }

    private func dayDetailDateString(_ info: DayTithiInfo, timeZone: TimeZone) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEEE, d MMMM yyyy"
        df.timeZone = timeZone
        return df.string(from: info.date)
    }

    // MARK: - Helpers

    private func cellBackground(_ info: DayTithiInfo, isToday: Bool) -> Color {
        if isToday { return .blue.opacity(0.05) }
        if isPurnima(info) { return .yellow.opacity(0.04) }
        if isAmavasya(info) { return .indigo.opacity(0.04) }
        return Color(nsColor: .controlBackgroundColor).opacity(0.6)
    }

    private func isPurnima(_ info: DayTithiInfo) -> Bool {
        info.tithi == .purnima
    }

    private func isAmavasya(_ info: DayTithiInfo) -> Bool {
        info.tithi == .amavasya
    }

    private func isCurrentDay(_ info: DayTithiInfo) -> Bool {
        let cal = Calendar.current
        let now = Date()
        return cal.component(.year, from: now) == displayYear
            && cal.component(.month, from: now) == displayMonth
            && cal.component(.day, from: now) == info.dayOfMonth
    }

    private var tithiTimeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = TimeZone(identifier: viewModel.timeZoneID) ?? .current
        return f
    }

    private var monthYearString: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let comps = DateComponents(year: displayYear, month: displayMonth, day: 1)
        if let date = cal.date(from: comps) {
            return df.string(from: date)
        }
        return "\(displayMonth)/\(displayYear)"
    }

    // MARK: - Navigation

    private func goToPreviousMonth() {
        selectedDay = nil
        if displayMonth == 1 {
            displayMonth = 12
            displayYear -= 1
        } else {
            displayMonth -= 1
        }
        Task { await loadMonth() }
    }

    private func goToNextMonth() {
        selectedDay = nil
        if displayMonth == 12 {
            displayMonth = 1
            displayYear += 1
        } else {
            displayMonth += 1
        }
        Task { await loadMonth() }
    }

    // MARK: - Data Loading

    private func loadMonth() async {
        isLoading = true
        selectedDay = nil
        let ephemeris = EphemerisActor()
        await ephemeris.initialize(ephemerisPath: nil)
        await ephemeris.setSiderealMode(AyanamsaType.lahiri.seMode)

        let calculator = TithiCalculator()
        let data = await calculator.computeMonth(
            year: displayYear,
            month: displayMonth,
            timeZoneID: viewModel.timeZoneID,
            ephemeris: ephemeris
        )

        await ephemeris.close()
        monthData = data
        isLoading = false
    }
}
