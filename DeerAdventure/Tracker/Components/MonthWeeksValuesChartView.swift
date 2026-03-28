import SwiftUI

struct MonthWeeksValuesChartView: View {
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
