//
//  KirchbergConfettiView.swift
//  Originally ConfettiView.swift by Kirill Kostarev
//  https://github.com/Kirchberg/Confetti
//

import UIKit

public final class KirchbergConfettiView: UIView {

    // MARK: - Public Types

    public enum Direction {
        case left
        case right
        case top
        case bottom
    }

    public enum Animation {
        case `default`
    }

    // MARK: - Public Init

    public init(
        emitters: [ConfettiEmitter],
        direction: Direction,
        animation: Animation,
        configuration: ConfettiConfiguration? = nil
    ) {
        self.emitters = emitters
        self.direction = direction
        self.animation = animation
        self.configuration = configuration ?? ConfettiConfiguration()
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    public override func willMove(toSuperview newSuperview: UIView?) {
        guard let superview = newSuperview else { return }
        frame = superview.bounds
        isUserInteractionEnabled = false
    }

    public func emit() {
        guard !shouldReduceMotion else { return }
        switch direction {
        case .left:
            emitLeft(emitters, animation: animation)
        case .right:
            emitRight(emitters, animation: animation)
        case .top:
            emitTop(emitters, animation: animation)
        case .bottom:
            emitBottom(emitters, animation: animation)
        }
    }

    public func clear() {
        layer.removeAllAnimations()
        layer.sublayers?.forEach {
            $0.removeAllAnimations()
            $0.removeFromSuperlayer()
        }
    }

    // MARK: - Private Properties

    private let emitters: [ConfettiEmitter]
    private let direction: Direction
    private let animation: Animation
    private let configuration: ConfettiConfiguration

    private var shouldReduceMotion: Bool {
        configuration.respectReducedMotion && UIAccessibility.isReduceMotionEnabled
    }

    // MARK: - Private Methods

    private func emitLeft(_ emitters: [ConfettiEmitter], animation: Animation) {
        let confettiLayer = ConfettiLayer(emitters, .left, configuration: configuration)
        configure(confettiLayer: confettiLayer, animation: animation)
    }

    private func emitRight(_ emitters: [ConfettiEmitter], animation: Animation) {
        let confettiLayer = ConfettiLayer(emitters, .right, configuration: configuration)
        configure(confettiLayer: confettiLayer, animation: animation)
    }

    private func emitTop(_ emitters: [ConfettiEmitter], animation: Animation) {
        let confettiLayer = ConfettiLayer(emitters, .top, configuration: configuration)
        configure(confettiLayer: confettiLayer, animation: animation)
    }

    private func emitBottom(_ emitters: [ConfettiEmitter], animation: Animation) {
        let confettiLayer = ConfettiLayer(emitters, .bottom, configuration: configuration)
        configure(confettiLayer: confettiLayer, animation: animation)
    }

    private func addGravityAnimation(to layer: CAEmitterLayer, emitters: [ConfettiEmitter]) {
        for emitter in emitters {
            let animation = CABasicAnimation(keyPath: "emitterCells.\(emitter.id).yAcceleration")
            animation.duration = configuration.gravityAnimationDuration
            animation.fromValue = 0
            animation.toValue = configuration.gravity
            animation.timingFunction = CAMediaTimingFunction(name: .easeIn)

            layer.add(animation, forKey: "gravity.\(emitter.id)")
        }
    }

    private func addBirthrateAnimation(to layer: CAEmitterLayer) {
        let animation = CABasicAnimation(keyPath: "birthRate")
        animation.duration = configuration.birthRateAnimationDuration
        animation.fromValue = 1
        animation.toValue = 0

        layer.add(animation, forKey: "birthRate")
        layer.birthRate = 0
    }

    private func configure(
        confettiLayer: ConfettiLayer,
        animation: Animation
    ) {
        confettiLayer.frame = self.bounds
        confettiLayer.needsDisplayOnBoundsChange = true

        layer.addSublayer(confettiLayer)

        CATransaction.begin()
        switch animation {
        case .`default`:
            addGravityAnimation(to: confettiLayer, emitters: emitters)
            addBirthrateAnimation(to: confettiLayer)
        }
        CATransaction.commit()
    }

}

// MARK: - Custom Styles

extension KirchbergConfettiView {

    public static let top = KirchbergConfettiView(
        emitters: Static.defaultEmitters,
        direction: .top,
        animation: .default
    )

    public static let left = KirchbergConfettiView(
        emitters: Static.defaultEmitters,
        direction: .left,
        animation: .default
    )

    public static let right = KirchbergConfettiView(
        emitters: Static.defaultEmitters,
        direction: .right,
        animation: .default
    )

    public static let bottom = KirchbergConfettiView(
        emitters: Static.defaultEmitters,
        direction: .bottom,
        animation: .default
    )

    private enum Static {
        static let defaultEmitters: [ConfettiEmitter] = [
            .shape(.rectangle, color: .systemRed),
            .shape(.rectangle, color: .systemPink),
            .shape(.rectangle, color: .systemYellow),
            .shape(.rectangle, color: .systemTeal),
            .shape(.rectangle, color: .systemBlue),
            .shape(.circle, color: .systemGreen),
            .shape(.circle, color: .systemRed),
            .shape(.circle, color: .systemPink),
            .shape(.circle, color: .systemYellow),
            .shape(.circle, color: .systemTeal),
            .shape(.circle, color: .systemBlue),
            .shape(.circle, color: .systemGreen)
        ]
    }

}
