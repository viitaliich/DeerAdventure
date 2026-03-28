import SwiftUI

struct ConfettiCelebrationView: View {
    let trigger: Int
    @State private var progress: CGFloat = 0

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    private let particleIndices: [Int] = Array(0..<120)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particleIndices, id: \.self) { (index: Int) in
                    particleView(index: index, size: geo.size)
                }
            }
        }
        .id(trigger)
        .onAppear {
            progress = 0
            withAnimation(.linear(duration: 2.0)) {
                progress = 1
            }
        }
    }

    private func random(_ index: Int, _ seed: Int) -> CGFloat {
        let value = sin(Double(index * 37 + seed * 101)) * 10_000
        return CGFloat(value - floor(value))
    }

    @ViewBuilder
    private func particleView(index: Int, size: CGSize) -> some View {
        // Bouquet-like motion: particles start from one bottom point and fan upward.
        let originX = size.width * 0.5
        let startX = originX + (random(index + 1, trigger) - 0.5) * size.width * 0.12
        let startY = size.height + 16 + random(index + 2, trigger) * 18

        // Angle around vertical axis (-90°), with left/right spread like bouquet stems.
        let angle = (-90.0 + (Double(random(index + 3, trigger)) - 0.5) * 70.0) * .pi / 180
        let travel = size.height * (0.95 + random(index + 4, trigger) * 0.40)
        let easeOut = 1 - pow(1 - progress, 2.1)

        // Slight natural sway while moving up.
        let sway = sin(progress * .pi * (1.2 + random(index + 5, trigger) * 1.6))
        let swayAmount = (random(index + 6, trigger) - 0.5) * size.width * 0.035

        let x = startX + CGFloat(cos(angle)) * travel * easeOut + sway * swayAmount
        let y = startY + CGFloat(sin(angle)) * travel * easeOut

        let spin = (random(index + 7, trigger) - 0.5) * 160
        let colorIndex = Int(random(index + 8, trigger) * CGFloat(colors.count)) % colors.count
        let width = 4 + random(index + 9, trigger) * 3
        let height = 8 + random(index + 10, trigger) * 5

        let visibility = max(0, 1 - max(0, progress - 0.80) / 0.20)

        RoundedRectangle(cornerRadius: 2)
            .fill(colors[colorIndex])
            .frame(width: width, height: height)
            .position(
                x: x,
                y: y
            )
            .rotationEffect(.degrees(Double(spin * progress)))
            .scaleEffect(0.88 + 0.24 * progress)
            .opacity(visibility)
    }
}
