import UIKit

enum AppHaptics {
    static func playButtonTap() {
        let haptic = UIImpactFeedbackGenerator(style: .soft)
        haptic.prepare()
        haptic.impactOccurred(intensity: 0.5)
    }
}
