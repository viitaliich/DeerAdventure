//
//  ContentView.swift
//  DeerAdventure
//
//  Created by Vitalii Klimov on 07.02.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    struct MonthItem: Identifiable, Hashable {
        let name: String
        let number: Int
        var id: Int { number }
    }

    struct MonthSelection: Identifiable, Hashable {
        let year: Int
        let month: MonthItem

        // ??? Why string
        var id: String { "\(year)-\(month.id)" }
    }

    // ??? Refactor years - do not hardcode them
    private let years = [2026, 2027, 2028]
    // ??? Maybe we have some built in struct for this? (Can we don't hardcode it?)
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

    // ??? Rename Genesis to something else
    @Namespace private var monthAnimation
    @Query private var dayEntries: [DayValueEntry]
    @State private var selectedMonth: MonthSelection?
    @State private var showMonthDetail = false
    @State private var launchWeekOfYear: Int?
    @State private var showGenesisGame = false
    @State private var showHelpPopup = false

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }

    var body: some View {
        // ??? Can we create some sort of Style and apply it to elements instead of manualy setup visual properties
        // separately for ech component?
        
        // ??? Lots of .methods. Maybe refactor this to be more clear?
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            mainCalendarLayer
                .blur(radius: showMonthDetail ? 6 : 0)  // ??? does it work?
                .opacity(showMonthDetail ? 0.55 : 1)  // ??? does it work?
                .allowsHitTesting(!showMonthDetail)  // ??? does it work?

            if let selection = selectedMonth, showMonthDetail {
                MonthDetailOverlay(
                    selection: selection,
                    matchedID: selection.id,
                    namespace: monthAnimation,
                    closeAction: closeMonthDetail,
                    initialWeekOfYear: launchWeekOfYear,
                    onInitialWeekHandled: { launchWeekOfYear = nil }
                )
                .zIndex(2) // ??? do we need this
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showMonthDetail)
        // ??? This logic is strange
        .fullScreenCover(isPresented: $showGenesisGame) {
            GameViewV2()
        }
        .sheet(isPresented: $showHelpPopup) {
            HelpPopupView()
                .presentationDetents([.medium, .large]) // ??? Check other options
                .presentationDragIndicator(.visible)    // change to hidden ???
                .presentationBackground(.ultraThinMaterial)
        }
        .onAppear {
            openCurrentWeekOnLaunch()
        }
    }

    private var mainCalendarLayer: some View {
        // ??? do we need alignment: .bottom
        ZStack(alignment: .bottom) {
            // ??? refactor alignments and composition
            ScrollView {
                VStack(spacing: 30) {
                    ForEach(years, id: \.self) { year in
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(year)")
                                .font(.system(size: 40, weight: .bold, design: .default))
                            // ??? red marking of current date must be refactored.
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
                            // ??? research and refactor these
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Color.clear.frame(height: 120)  // ??? WTF is this?
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

        // ??? Why do we need this async
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
//            if !showMonthDetail {
                selectedMonth = nil
//            }
//        }
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

    // ??? Why string? Maybe we can not use strings in the app at all?
    private func monthID(for month: MonthItem, year: Int) -> String {
        "\(year)-\(month.id)"
    }

    // ??? Refactor. And why string again
    private func monthTotal(for month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        return dayEntries.reduce(into: 0) { result, entry in
            guard let date = DayValueKey.parse(entry.dateKey) else { return }
            let comps = calendar.dateComponents([.year, .month], from: date)
            if comps.year == year, comps.month == month {
                result += max(0, entry.value)   // ??? do we need max here? we can't have negative values
            }
        }
    }

    // ??? Refactor?
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

    private var bottomBar: some View {
        BottomLeftButtonContainer(addBackgroundStrip: true) {
            HStack(spacing: 0) {
                BottomPillButton(title: "Today", systemImage: nil, action: openCurrentWeekOnLaunch)
                Spacer(minLength: 0)
                BottomPillButton(title: "Play", systemImage: nil, action: { showGenesisGame = true })
                Spacer(minLength: 0)
                BottomCircleButton(title: "?", action: { showHelpPopup = true })
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [DayValueEntry.self], inMemory: true)
}
