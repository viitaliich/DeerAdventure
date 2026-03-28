import SwiftUI
import SwiftData

struct MonthDetailOverlay: View {
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
