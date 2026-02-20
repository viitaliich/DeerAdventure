//
//  ContentView.swift
//  DeerAdventure
//
//  Created by Vitalii Klimov on 07.02.2026.
//

import SwiftUI
import AudioToolbox
import UIKit
import SwiftData

@Model
final class DayValueEntry {
    @Attribute(.unique) var dateKey: String
    var value: Int

    init(dateKey: String, value: Int) {
        self.dateKey = dateKey
        self.value = value
    }
}

private enum DayValueKey {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func make(from date: Date) -> String {
        formatter.string(from: Calendar.current.startOfDay(for: date))
    }

    static func parse(_ key: String) -> Date? {
        formatter.date(from: key)
    }
}

private enum BottomButtonLayout {
    static let horizontalInset: CGFloat = 32
    static let bottomInset: CGFloat = 32
}

private enum BottomButtonStyle {
    static let fontSize: CGFloat = 24
    static let horizontalPadding: CGFloat = 34
    static let verticalPadding: CGFloat = 16
    static let backgroundOpacity: CGFloat = 0.85
}

private enum AppHaptics {
    static func playButtonTap() {
        let haptic = UIImpactFeedbackGenerator(style: .soft)
        haptic.prepare()
        haptic.impactOccurred(intensity: 0.5)
    }
}

private struct WeekInfo: Identifiable {
    let id: Int
    let weekOfYear: Int
    let title: String
    let range: String
    let trailingValue: String
    let monthName: String
    let year: Int
    let startDate: Date
    let endDate: Date
}

struct ContentView: View {
    struct MonthItem: Identifiable, Hashable {
        let name: String
        let number: Int
        var id: Int { number }
    }

    struct MonthSelection: Identifiable, Hashable {
        let year: Int
        let month: MonthItem

        var id: String { "\(year)-\(month.id)" }
    }

    private let years = [2026, 2027, 2028]
    private let months: [MonthItem] = [
        .init(name: "Jan", number: 1), .init(name: "Feb", number: 2), .init(name: "Mar", number: 3),
        .init(name: "Apr", number: 4), .init(name: "May", number: 5), .init(name: "Jun", number: 6),
        .init(name: "Jul", number: 7), .init(name: "Aug", number: 8), .init(name: "Sep", number: 9),
        .init(name: "Oct", number: 10), .init(name: "Nov", number: 11), .init(name: "Dec", number: 12)
    ]

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    @Namespace private var monthAnimation
    @Query private var dayEntries: [DayValueEntry]
    @State private var selectedMonth: MonthSelection?
    @State private var showMonthDetail = false
    @State private var launchWeekOfYear: Int?

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            mainCalendarLayer
                .blur(radius: showMonthDetail ? 6 : 0)
                .opacity(showMonthDetail ? 0.55 : 1)
                .allowsHitTesting(!showMonthDetail)

            if let selection = selectedMonth, showMonthDetail {
                MonthDetailOverlay(
                    selection: selection,
                    matchedID: selection.id,
                    namespace: monthAnimation,
                    closeAction: closeMonthDetail,
                    initialWeekOfYear: launchWeekOfYear,
                    onInitialWeekHandled: { launchWeekOfYear = nil }
                )
                .zIndex(2)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showMonthDetail)
        .onAppear {
            openCurrentWeekOnLaunch()
        }
    }

    private var mainCalendarLayer: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 30) {
                    ForEach(years, id: \.self) { year in
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(year)")
                                .font(.system(size: 40, weight: .bold, design: .default))
                                .foregroundStyle(year == 2026 ? Color.red : Color.primary)

                            Divider()

                            LazyVGrid(columns: columns, alignment: .leading, spacing: 2) {
                                ForEach(months) { month in
                                    Button {
                                        AppHaptics.playButtonTap()
                                        openMonthDetail(month, in: year)
                                    } label: {
                                        MonthCardView(
                                            name: month.name,
                                            number: monthTotal(for: month.number, year: year),
                                            isCurrentMonth: year == currentYear && month.number == currentMonth,
                                            nameFontSize: 40,
                                            numberFontSize: 40
                                        )
                                            .matchedGeometryEffect(id: monthID(for: month, year: year), in: monthAnimation)
                                    }
                                    .buttonStyle(.plain)
                                    .offset(monthSpreadOffset(for: month))
                    
                                    .opacity(selectedMonth?.id == monthID(for: month, year: year) && showMonthDetail ? 0 : 1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }

            bottomBar
        }
    }

    private func openMonthDetail(_ month: MonthItem, in year: Int) {
        selectedMonth = MonthSelection(year: year, month: month)
        withAnimation {
            showMonthDetail = true
        }
    }

    private func closeMonthDetail() {
        withAnimation {
            showMonthDetail = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if !showMonthDetail {
                selectedMonth = nil
            }
        }
    }

    private func monthSpreadOffset(for month: MonthItem) -> CGSize {
        guard showMonthDetail, let selectedMonth else { return .zero }

        let index = month.number - 1
        let selectedIndex = selectedMonth.month.number - 1

        let row = index / 3
        let column = index % 3
        let selectedRow = selectedIndex / 3
        let selectedColumn = selectedIndex % 3

        let dx = CGFloat(column - selectedColumn) * 14
        let dy = CGFloat(row - selectedRow) * 20

        return CGSize(width: dx, height: dy)
    }

    private func monthID(for month: MonthItem, year: Int) -> String {
        "\(year)-\(month.id)"
    }

    private func monthTotal(for month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        return dayEntries.reduce(into: 0) { result, entry in
            guard let date = DayValueKey.parse(entry.dateKey) else { return }
            let comps = calendar.dateComponents([.year, .month], from: date)
            if comps.year == year, comps.month == month {
                result += max(0, entry.value)
            }
        }
    }

    private func openCurrentWeekOnLaunch() {
        guard selectedMonth == nil, !showMonthDetail else { return }

        let calendar = Calendar.current
        let today = Date()

        let comps = calendar.dateComponents([.year, .month, .weekOfYear], from: today)
        guard
            let year = comps.year,
            let monthNumber = comps.month,
            let weekOfYear = comps.weekOfYear,
            years.contains(year),
            let month = months.first(where: { $0.number == monthNumber })
        else { return }

        selectedMonth = MonthSelection(year: year, month: month)
        launchWeekOfYear = weekOfYear
        showMonthDetail = true
    }

    private var topBar: some View {
        HStack {
            Spacer()

            HStack(spacing: 18) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 30, weight: .medium))
                Image(systemName: "plus")
                    .font(.system(size: 34, weight: .light))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.white.opacity(0.8), in: Capsule())
        }
    }

    private var bottomBar: some View {
        BottomLeftButtonContainer(addBackgroundStrip: false) {
            BottomPillButton(title: "Today", systemImage: nil, action: openCurrentWeekFromToday)
        }
    }

    private func openCurrentWeekFromToday() {
        openCurrentWeekOnLaunch()
    }
}

private struct MonthDetailOverlay: View {
    let selection: ContentView.MonthSelection
    let matchedID: String
    let namespace: Namespace.ID
    let closeAction: () -> Void
    let initialWeekOfYear: Int?
    let onInitialWeekHandled: () -> Void

    @Query private var dayEntries: [DayValueEntry]
    @Namespace private var weekAnimation
    @State private var selectedWeek: WeekInfo?
    @State private var showWeekDates = false
    @State private var didHandleInitialWeek = false

    private var weekRows: [WeekInfo] {
        let calendar = Calendar.current
        let monthStart = monthStartDate
        let monthEnd = monthEndDate
        let targetYear = selection.year
        let targetMonth = selection.month.number

        guard let firstWeek = calendar.dateInterval(of: .weekOfYear, for: monthStart) else {
            return []
        }

        var rows: [WeekInfo] = []
        var currentWeekStart = firstWeek.start
        if currentWeekStart < monthStart {
            currentWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) ?? currentWeekStart
        }
        var rowID = 1

        while currentWeekStart <= monthEnd {
            let comps = calendar.dateComponents([.year, .month], from: currentWeekStart)
            guard comps.year == targetYear, comps.month == targetMonth else {
                break
            }

            guard let currentWeek = calendar.dateInterval(of: .weekOfYear, for: currentWeekStart) else {
                break
            }

            let weekStart = currentWeek.start
            let weekEndExclusive = currentWeek.end
            let weekEnd = calendar.date(byAdding: .day, value: -1, to: weekEndExclusive) ?? weekStart

            let weekOfYear = calendar.component(.weekOfYear, from: currentWeek.start)
            let weekTotal = totalValue(from: weekStart, to: weekEnd)

            rows.append(
                WeekInfo(
                    id: rowID,
                    weekOfYear: weekOfYear,
                    title: "Week \(weekOfYear)",
                    range: "\(Self.dateFormatter.string(from: weekStart)) - \(Self.dateFormatter.string(from: weekEnd))",
                    trailingValue: "\(weekTotal)",
                    monthName: selection.month.name,
                    year: selection.year,
                    startDate: weekStart,
                    endDate: weekEnd
                )
            )

            rowID += 1
            currentWeekStart = weekEndExclusive
        }

        return rows
    }

    private var monthStartDate: Date {
        Calendar.current.date(from: DateComponents(year: selection.year, month: selection.month.number, day: 1)) ?? Date()
    }

    private var monthEndDate: Date {
        let calendar = Calendar.current
        let dayCount = calendar.range(of: .day, in: .month, for: monthStartDate)?.count ?? 30
        return calendar.date(from: DateComponents(year: selection.year, month: selection.month.number, day: dayCount)) ?? monthStartDate
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()

    private var todayComponents: DateComponents {
        Calendar.current.dateComponents([.year, .month, .weekOfYear], from: Date())
    }

    private var isCurrentMonth: Bool {
        todayComponents.year == selection.year && todayComponents.month == selection.month.number
    }

    private var monthTotal: Int {
        totalValue(from: monthStartDate, to: monthEndDate)
    }

    private var monthMaxProgressTotal: Int {
        weekRows.reduce(0) { partial, week in
            partial + weekMaxProgress(for: week)
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 14) {
                        MonthCardView(
                            name: selection.month.name,
                            number: monthTotal,
                            isCurrentMonth: false,
                            expandsToMaxWidth: false,
                            fixedNumberWidth: 180
                        )
                        .matchedGeometryEffect(id: matchedID, in: namespace)
                        .layoutPriority(2)

                        ThickProgressBarView(
                            value: Double(min(monthTotal, monthMaxProgressTotal)),
                            total: Double(max(monthMaxProgressTotal, 1))
                        )
                        .frame(minWidth: 90, maxWidth: .infinity)
                        .layoutPriority(0)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(weekRows) { week in
                            Button {
                                AppHaptics.playButtonTap()
                                openWeekDates(week)
                            } label: {
                                WeekRowView(
                                    week: week,
                                    isCurrentWeek: isCurrentMonth && todayComponents.weekOfYear == week.weekOfYear
                                )
                                    .matchedGeometryEffect(id: weekMatchedID(for: week), in: weekAnimation)
                            }
                            .buttonStyle(.plain)
                            .opacity(selectedWeek?.id == week.id && showWeekDates ? 0 : 1)
                        }
                    }
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    Divider()

                    MonthWeeksValuesChartView(weeks: weekRows)

                    Color.clear.frame(height: 140)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .scaleEffect(showWeekDates ? 0.96 : 1)
            .opacity(showWeekDates ? 0.5 : 1)
            .blur(radius: showWeekDates ? 4 : 0)
            .allowsHitTesting(!showWeekDates)

            if let selectedWeek, showWeekDates {
                WeekDatesOverlay(
                    week: selectedWeek,
                    matchedID: weekMatchedID(for: selectedWeek),
                    namespace: weekAnimation,
                    closeAction: closeWeekDates
                )
                    .transition(.opacity)
                    .zIndex(2)
            }

            if !showWeekDates {
                BottomLeftButtonContainer {
                    BottomPillButton(title: "\(selection.year)", systemImage: "chevron.left", action: closeAction)
                }
            }

            HStack(spacing: 0) {
                EdgeSwipeBackArea(action: closeAction)
                Spacer(minLength: 0)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.86), value: showWeekDates)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGray6).ignoresSafeArea())
        .onAppear {
            openInitialWeekIfNeeded()
        }
    }

    private func openWeekDates(_ week: WeekInfo) {
        selectedWeek = week
        withAnimation {
            showWeekDates = true
        }
    }

    private func closeWeekDates() {
        withAnimation {
            showWeekDates = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if !showWeekDates {
                selectedWeek = nil
            }
        }
    }

    private func weekMatchedID(for week: WeekInfo) -> String {
        "week-\(selection.id)-\(week.id)"
    }

    private func openInitialWeekIfNeeded() {
        guard !didHandleInitialWeek else { return }
        didHandleInitialWeek = true

        guard let initialWeekOfYear,
              let week = weekRows.first(where: { $0.weekOfYear == initialWeekOfYear }) else {
            onInitialWeekHandled()
            return
        }

        selectedWeek = week
        showWeekDates = true
        onInitialWeekHandled()
    }

    private func totalValue(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        return dayEntries.reduce(into: 0) { result, entry in
            guard let date = DayValueKey.parse(entry.dateKey) else { return }
            let day = calendar.startOfDay(for: date)
            if day >= startDate && day <= endDate {
                result += max(0, entry.value)
            }
        }
    }

    private func weekMaxProgress(for week: WeekInfo) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: week.startDate)
        let end = calendar.startOfDay(for: week.endDate)
        let dayCount = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
        return max(1, dayCount) * 10
    }
}

private struct WeekDatesOverlay: View {
    let week: WeekInfo
    let matchedID: String
    let namespace: Namespace.ID
    let closeAction: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var dayValues: [Date: Int] = [:]
    @State private var showConfetti = false
    @State private var confettiTrigger = 0

    private var datesInWeek: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        var current = week.startDate

        while current <= week.endDate {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
            if dates.count > 7 { break }
        }

        return dates
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()

    private var weekTotalValue: Int {
        datesInWeek.reduce(0) { partial, date in
            partial + value(for: date)
        }
    }

    private var weekMaxProgressTotal: Int {
        datesInWeek.count * 10
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 14) {
                        MonthCardView(
                            name: "Week \(week.weekOfYear)",
                            number: weekTotalValue,
                            isCurrentMonth: false,
                            expandsToMaxWidth: false,
                            fixedNumberWidth: 180
                        )
                        .matchedGeometryEffect(id: matchedID, in: namespace)
                        .layoutPriority(2)

                        ThickProgressBarView(
                            value: Double(min(weekTotalValue, weekMaxProgressTotal)),
                            total: Double(max(weekMaxProgressTotal, 1))
                        )
                        .frame(minWidth: 90, maxWidth: .infinity)
                        .layoutPriority(0)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(datesInWeek, id: \.self) { date in
                            let currentValue = value(for: date)
                            let currentValueText = "\(currentValue)"

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(Self.dateFormatter.string(from: date))
                                        .foregroundStyle(Calendar.current.isDateInToday(date) ? Color.red : Color.primary)

                                    ProgressView(value: progressValue(for: date), total: 10)
                                        .tint(progressValue(for: date) >= 10 ? .green : .blue)
                                        .frame(maxWidth: .infinity)

                                    HStack(spacing: 10) {
                                        Button("−") {
                                            AppHaptics.playButtonTap()
                                            decrementValue(for: date)
                                        }

                                        Text("\(currentValue)")
                                            .monospacedDigit()
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: false)
                                            .frame(width: currentValueText.count <= 2 ? 36 : nil, alignment: .center)

                                        Button("+") {
                                            AppHaptics.playButtonTap()
                                            incrementValue(for: date)
                                        }
                                    }
                                }

                                if currentValue > 0 {
                                    LazyVGrid(
                                        columns: [GridItem(.adaptive(minimum: 24), spacing: 4)],
                                        alignment: .leading,
                                        spacing: 4
                                    ) {
                                        ForEach(0..<currentValue, id: \.self) { _ in
                                            Text("🦌")
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .font(.system(size: 24, weight: .semibold, design: .default))

                    Color.clear.frame(height: 140)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            if showConfetti {
                ConfettiCelebrationView(trigger: confettiTrigger)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            BottomLeftButtonContainer {
                BottomPillButton(
                    title: "\(week.monthName)",
                    systemImage: "chevron.left",
                    action: closeAction
                )
            }

            HStack(spacing: 0) {
                EdgeSwipeBackArea(action: closeAction)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGray6).ignoresSafeArea())
        .onAppear {
            initializeValuesIfNeeded()
        }
    }

    private func dayKey(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func initializeValuesIfNeeded() {
        let persisted = loadPersistedValues()

        for date in datesInWeek {
            let key = dayKey(date)
            dayValues[key] = persisted[DayValueKey.make(from: key)] ?? 0
        }
    }

    private func value(for date: Date) -> Int {
        dayValues[dayKey(date), default: 0]
    }

    private func progressValue(for date: Date) -> Double {
        Double(min(value(for: date), 10))
    }

    private func incrementValue(for date: Date) {
        let key = dayKey(date)
        let previous = dayValues[key, default: 0]
        let newValue = previous + 1
        dayValues[key, default: 0] = newValue
        persist(value: newValue, for: key)

        if previous < 10, dayValues[key, default: 0] >= 10 {
            fireConfetti()
        }
    }

    private func decrementValue(for date: Date) {
        let key = dayKey(date)
        let newValue = max(0, dayValues[key, default: 0] - 1)
        dayValues[key, default: 0] = newValue
        persist(value: newValue, for: key)
    }

    private func loadPersistedValues() -> [String: Int] {
        let descriptor = FetchDescriptor<DayValueEntry>()
        let entries = (try? modelContext.fetch(descriptor)) ?? []
        return Dictionary(uniqueKeysWithValues: entries.map { ($0.dateKey, $0.value) })
    }

    private func persist(value: Int, for date: Date) {
        let key = DayValueKey.make(from: date)
        var descriptor = FetchDescriptor<DayValueEntry>(predicate: #Predicate { $0.dateKey == key })
        descriptor.fetchLimit = 1

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.value = value
        } else {
            modelContext.insert(DayValueEntry(dateKey: key, value: value))
        }

        try? modelContext.save()
    }

    private func fireConfetti() {
        confettiTrigger += 1
        showConfetti = true
        playCelebrationFeedback()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            showConfetti = false
        }
    }

    private func playCelebrationFeedback() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.prepare()
        haptic.impactOccurred(intensity: 0.7)

        AudioServicesPlaySystemSound(1025)
    }
}

private struct ConfettiCelebrationView: View {
    let trigger: Int
    @State private var progress: CGFloat = 0

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    private let particleIndices: [Int] = Array(0..<120)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particleIndices, id: \.self) { (index: Int) in
                    particleView(index: index, size: geo.size)
                }
            }
        }
        .id(trigger)
        .onAppear {
            progress = 0
            withAnimation(.linear(duration: 2.0)) {
                progress = 1
            }
        }
    }

    private func random(_ index: Int, _ seed: Int) -> CGFloat {
        let value = sin(Double(index * 37 + seed * 101)) * 10_000
        return CGFloat(value - floor(value))
    }

    @ViewBuilder
    private func particleView(index: Int, size: CGSize) -> some View {
        // Bouquet-like motion: particles start from one bottom point and fan upward.
        let originX = size.width * 0.5
        let startX = originX + (random(index + 1, trigger) - 0.5) * size.width * 0.12
        let startY = size.height + 16 + random(index + 2, trigger) * 18

        // Angle around vertical axis (-90°), with left/right spread like bouquet stems.
        let angle = (-90.0 + (Double(random(index + 3, trigger)) - 0.5) * 70.0) * .pi / 180
        let travel = size.height * (0.95 + random(index + 4, trigger) * 0.40)
        let easeOut = 1 - pow(1 - progress, 2.1)

        // Slight natural sway while moving up.
        let sway = sin(progress * .pi * (1.2 + random(index + 5, trigger) * 1.6))
        let swayAmount = (random(index + 6, trigger) - 0.5) * size.width * 0.035

        let x = startX + CGFloat(cos(angle)) * travel * easeOut + sway * swayAmount
        let y = startY + CGFloat(sin(angle)) * travel * easeOut

        let spin = (random(index + 7, trigger) - 0.5) * 160
        let colorIndex = Int(random(index + 8, trigger) * CGFloat(colors.count)) % colors.count
        let width = 4 + random(index + 9, trigger) * 3
        let height = 8 + random(index + 10, trigger) * 5

        let visibility = max(0, 1 - max(0, progress - 0.80) / 0.20)

        RoundedRectangle(cornerRadius: 2)
            .fill(colors[colorIndex])
            .frame(width: width, height: height)
            .position(
                x: x,
                y: y
            )
            .rotationEffect(.degrees(Double(spin * progress)))
            .scaleEffect(0.88 + 0.24 * progress)
            .opacity(visibility)
    }
}

private struct WeekRowView: View {
    let week: WeekInfo
    let isCurrentWeek: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(week.title)
                .foregroundStyle(isCurrentWeek ? Color.red : Color.primary)
                .frame(width: 104, alignment: .leading)

            Text(week.range)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(week.trailingValue)
                .foregroundStyle(isCurrentWeek ? Color.red : Color.primary)
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
    }
}

private struct MonthWeeksValuesChartView: View {
    let weeks: [WeekInfo]

    private var maxValue: Int {
        max(weeks.map { Int($0.trailingValue) ?? 0 }.max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(weeks) { week in
                let value = Int(week.trailingValue) ?? 0

                VStack(spacing: 4) {
                    Text("\(value)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)

                    GeometryReader { geo in
                        VStack {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.78))
                                .frame(height: max(6, CGFloat(value) / CGFloat(maxValue) * geo.size.height))
                        }
                    }

                    Text("W\(week.weekOfYear)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 130)
    }
}

private struct BottomPillButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    var body: some View {
        Button {
            AppHaptics.playButtonTap()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.system(size: BottomButtonStyle.fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, BottomButtonStyle.horizontalPadding)
            .padding(.vertical, BottomButtonStyle.verticalPadding)
            .background(.white.opacity(BottomButtonStyle.backgroundOpacity), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct BottomLeftButtonContainer<Content: View>: View {
    var addBackgroundStrip: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack {
            Spacer()
            HStack {
                content()
                Spacer()
            }
            .padding(.horizontal, BottomButtonLayout.horizontalInset)
            .padding(.bottom, BottomButtonLayout.bottomInset)
            .background(
                addBackgroundStrip
                ? Color(.systemGray6).opacity(BottomButtonStyle.backgroundOpacity)
                : Color.clear
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private struct EdgeSwipeBackArea: View {
    let action: () -> Void

    var body: some View {
        Color.clear
            .frame(width: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 18)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = abs(value.translation.height)

                        guard horizontal > 70, vertical < 70 else { return }
                        action()
                    }
            )
            .ignoresSafeArea()
    }
}

private struct MonthCardView: View {
    let name: String
    let number: Int
    var isCurrentMonth: Bool = false
    var expandsToMaxWidth: Bool = true
    var fixedNumberWidth: CGFloat? = nil
    var nameFontSize: CGFloat = 20
    var numberFontSize: CGFloat = 80

    private var numberText: String {
        "\(number)"
    }

    private var numberContainerWidth: CGFloat? {
        guard let fixedNumberWidth else { return nil }
        return numberText.count <= 2 ? fixedNumberWidth : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(name)
                .font(.system(size: nameFontSize, weight: .bold, design: .default))
                .minimumScaleFactor(0.5)
                .foregroundStyle(isCurrentMonth ? Color.red : Color.primary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(numberText)
                    .font(.system(size: numberFontSize, weight: .none, design: .default))
                    .monospacedDigit()
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .minimumScaleFactor(1)
                    .foregroundStyle(.primary)

                Text("🦌")
                    .font(.system(size: 40))
            }
            .frame(width: numberContainerWidth, alignment: .leading)
            .layoutPriority(1)
        }
        .frame(maxWidth: expandsToMaxWidth ? .infinity : nil, alignment: .leading)
        .padding(.vertical, 8)
    }
}

private struct ThickProgressBarView: View {
    let value: Double
    let total: Double

    private var normalizedTotal: Double {
        max(total, 1)
    }

    private var clampedValue: Double {
        min(value, normalizedTotal)
    }

    private var progressTint: Color {
        clampedValue >= normalizedTotal ? .green : .blue
    }

    var body: some View {
        ProgressView(value: clampedValue, total: normalizedTotal)
            .tint(progressTint)
            .scaleEffect(x: 1, y: 1.8, anchor: .center)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DayValueEntry.self], inMemory: true)
}

