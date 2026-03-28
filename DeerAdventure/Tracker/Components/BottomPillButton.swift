import SwiftUI

struct BottomPillButton: View {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .allowsTightening(true)
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
