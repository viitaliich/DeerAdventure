import SwiftUI

struct EdgeSwipeBackArea: View {
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
