import SwiftUI

struct ThickProgressBarView: View {
    let value: Double
    let total: Double

    private var normalizedTotal: Double {
        max(total, 1)
    }

    private var clampedValue: Double {
        min(value, normalizedTotal)
    }

    private var progressTint: Color {
        clampedValue >= normalizedTotal ? .green : .blue
    }

    var body: some View {
        ProgressView(value: clampedValue, total: normalizedTotal)
            .tint(progressTint)
            .scaleEffect(x: 1, y: 1.8, anchor: .center)
    }
}
