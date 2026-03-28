import SwiftUI
import SwiftData
import AudioToolbox

struct WeekDatesOverlay: View {
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
