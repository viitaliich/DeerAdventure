//
//  ConfettiConfiguration.swift
//  Originally by Kirill Kostarev
//  https://github.com/Kirchberg/Confetti
//

import UIKit

public struct ConfettiConfiguration {

    // MARK: - Public Properties

    public var particleCount: Int = 100
    public var spread: CGFloat = .pi / 2
    public var gravity: CGFloat = 4000
    public var startVelocity: CGFloat = 1000
    public var velocityDecay: CGFloat = 0.9
    public var drift: CGFloat = 0
    public var scale: CGFloat = 0.2
    public var scaleRange: CGFloat = 0.2
    public var lifetime: TimeInterval = 10.0
    public var gravityAnimationDuration: TimeInterval = 4.0
    public var birthRateAnimationDuration: TimeInterval = 1.0
    public var spin: CGFloat = .pi * 3
    public var spinRange: CGFloat = .pi * 3
    public var origin: CGPoint? = nil
    public var angle: CGFloat? = nil
    public var respectReducedMotion: Bool = false

    // MARK: - Public Init

    public init() {}

}

// MARK: - Presets

public extension ConfettiConfiguration {

    static let light: ConfettiConfiguration = {
        var configuration = ConfettiConfiguration()
        configuration.particleCount = 40
        configuration.gravity = 2200
        configuration.startVelocity = 700
        configuration.scale = 0.15
        configuration.scaleRange = 0.1
        configuration.lifetime = 8.0
        return configuration
    }()

    static let heavy: ConfettiConfiguration = {
        var configuration = ConfettiConfiguration()
        configuration.particleCount = 150
        configuration.gravity = 5200
        configuration.startVelocity = 1300
        configuration.scale = 0.3
        configuration.scaleRange = 0.25
        configuration.lifetime = 9.0
        return configuration
    }()

    static let burst: ConfettiConfiguration = {
        var configuration = ConfettiConfiguration()
        configuration.particleCount = 250
        configuration.spread = .pi
        configuration.startVelocity = 1600
        configuration.birthRateAnimationDuration = 0.4
        configuration.lifetime = 6.0
        return configuration
    }()

    static let gentle: ConfettiConfiguration = {
        var configuration = ConfettiConfiguration()
        configuration.particleCount = 25
        configuration.gravity = 1500
        configuration.startVelocity = 500
        configuration.scale = 0.12
        configuration.scaleRange = 0.08
        configuration.lifetime = 7.0
        return configuration
    }()

    static let fast: ConfettiConfiguration = {
        var configuration = ConfettiConfiguration()
        configuration.gravity = 5000
        configuration.startVelocity = 1500
        configuration.gravityAnimationDuration = 2.0
        configuration.lifetime = 5.0
        return configuration
    }()

    static let slow: ConfettiConfiguration = {
        var configuration = ConfettiConfiguration()
        configuration.gravity = 1800
        configuration.startVelocity = 600
        configuration.gravityAnimationDuration = 6.0
        configuration.lifetime = 12.0
        return configuration
    }()

}
