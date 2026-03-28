import SwiftUI

struct MonthCardView: View {
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
