//
//  ConfettiLayer.swift
//  Originally by Kirill Kostarev
//  https://github.com/Kirchberg/Confetti
//

import UIKit

public final class ConfettiLayer: CAEmitterLayer {

    // MARK: - Public Types

    public enum Direction {
        case left
        case right
        case top
        case bottom

        var longitude: CGFloat {
            switch self {
            case .left: return .pi * 0.25
            case .right: return .pi * 1.75
            case .top: return .pi
            case .bottom: return 0
            }
        }

        func position(rect: CGRect) -> CGPoint {
            switch self {
            case .left: return CGPoint(x: -50, y: rect.midY)
            case .right: return CGPoint(x: rect.maxX + 50, y: rect.midY)
            case .top: return CGPoint(x: rect.midX, y: -50)
            case .bottom: return CGPoint(x: rect.midX, y: rect.maxY + 50)
            }
        }
    }

    // MARK: - Public Init

    public init(
        _ emitters: [ConfettiEmitter],
        _ direction: Direction,
        configuration: ConfettiConfiguration = ConfettiConfiguration()
    ) {
        self.direction = direction
        self.configuration = configuration
        super.init()
        configure(emitters, direction)
    }

    public override init(layer: Any) {
        self.direction = .top
        self.configuration = ConfettiConfiguration()
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    public override func layoutSublayers() {
        super.layoutSublayers()

        emitterMode = .outline
        emitterShape = .line
        emitterSize = CGSize(width: 1.0, height: 1.0)
        emitterPosition = configuration.origin ?? direction.position(rect: frame)
    }

    // MARK: - Private Properties

    private let direction: Direction
    private let configuration: ConfettiConfiguration

    // MARK: - Private Methods

    private func configure(_ emitters: [ConfettiEmitter], _ direction: Direction) {
        emitterCells = emitters.map { content in
            let cell = CAEmitterCell()

            cell.name = content.id

            cell.contents = content.image.cgImage
            if let color = content.color {
                cell.color = color.cgColor
            }

            cell.beginTime = CACurrentMediaTime()
            cell.birthRate = Float(configuration.particleCount)
            cell.lifetime = Float(configuration.lifetime)

            cell.velocity = configuration.startVelocity
            cell.velocityRange = configuration.startVelocity * (1 - configuration.velocityDecay)
            cell.xAcceleration = configuration.drift
            cell.yAcceleration = configuration.gravity

            cell.emissionRange = configuration.spread
            cell.emissionLongitude = configuration.angle ?? direction.longitude

            cell.scale = configuration.scale
            cell.scaleRange = configuration.scaleRange
            cell.scaleSpeed = 0

            cell.spin = configuration.spin
            cell.spinRange = configuration.spinRange

            cell.setValue("plane", forKey: "particleType")
            cell.setValue(Double.pi, forKey: "orientationRange")
            cell.setValue(Double.pi / 2, forKey: "orientationLongitude")
            cell.setValue(Double.pi / 2, forKey: "orientationLatitude")

            return cell
        }
    }

}
