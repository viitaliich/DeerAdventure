import SwiftUI

struct WeekRowView: View {
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
