import UIKit
import AudioToolbox

enum AppHaptics {
    static func playButtonTap() {
        let haptic = UIImpactFeedbackGenerator(style: .soft)
        haptic.prepare()
        haptic.impactOccurred(intensity: 0.5)
    }

    static func playCelebration() {
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.prepare()
        haptic.impactOccurred(intensity: 0.7)
        AudioServicesPlaySystemSound(1025)
    }
}
