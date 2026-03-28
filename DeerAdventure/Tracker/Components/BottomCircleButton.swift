import SwiftUI

struct BottomCircleButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            AppHaptics.playButtonTap()
            action()
        } label: {
            Text(title)
                .font(.system(size: BottomButtonStyle.fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: 56, height: 56)
                .background(.white.opacity(BottomButtonStyle.backgroundOpacity), in: Circle())
        }
        .buttonStyle(.plain)
    }
}
