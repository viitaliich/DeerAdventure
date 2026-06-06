import SpriteKit

final class MobNode: SKSpriteNode {

    private static let size = CGSize(width: 20, height: 20)
    private static let speed: CGFloat = 35

    private var directionTick = 0
    private var currentDirection = CGVector.zero

    init() {
        super.init(texture: nil, color: .systemGreen, size: Self.size)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        name = "mob"
        zPosition = 20

        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 14, height: 14))
        physicsBody?.categoryBitMask    = PhysicsCategory.mob
        physicsBody?.collisionBitMask   = PhysicsCategory.terrain | PhysicsCategory.world
        physicsBody?.contactTestBitMask = PhysicsCategory.none
        physicsBody?.allowsRotation     = false
        physicsBody?.linearDamping      = 10
    }

    func updateAI() {
        directionTick += 1
        if directionTick >= 40 {
            directionTick = 0
            currentDirection = CGVector(
                dx: CGFloat(Int.random(in: -1...1)),
                dy: CGFloat(Int.random(in: -1...1))
            )
        }

        let len = hypot(currentDirection.dx, currentDirection.dy)
        guard len > 0.0001 else {
            physicsBody?.velocity = .zero
            return
        }
        physicsBody?.velocity = CGVector(
            dx: currentDirection.dx / len * Self.speed,
            dy: currentDirection.dy / len * Self.speed
        )

        if abs(currentDirection.dx) > abs(currentDirection.dy) {
            xScale = currentDirection.dx < 0 ? -1 : 1
        }
    }
}
