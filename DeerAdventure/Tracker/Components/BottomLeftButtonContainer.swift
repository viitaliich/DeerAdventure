import SwiftUI

struct BottomLeftButtonContainer<Content: View>: View {
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
            .padding(.top, addBackgroundStrip ? BottomButtonLayout.bottomInset : 0)
            .padding(.bottom, BottomButtonLayout.bottomInset)
            .background {
                if addBackgroundStrip {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
