import Foundation

enum ConfettiStyle {
    case custom
    case simibac    // requires ConfettiSwiftUI — File > Add Package Dependencies
    case kirchberg

    var animationDuration: TimeInterval {
        switch self {
        case .custom:    return 2.0
        case .simibac:   return 3.5
        case .kirchberg: return ConfettiConfig.kirchbergLifetime
        }
    }
}

enum ConfettiConfig {
    static let style: ConfettiStyle = .kirchberg
    static let kirchbergLifetime: TimeInterval = 3.0
}
