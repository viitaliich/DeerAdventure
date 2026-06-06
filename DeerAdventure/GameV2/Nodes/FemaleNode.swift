import SpriteKit

final class FemaleNode: SKSpriteNode {

    private static let size = CGSize(width: 24, height: 24)
    private static let speed: CGFloat = 45

    var canBreed = true

    private var directionTick = 0
    private var currentDirection = CGVector.zero

    init() {
        super.init(texture: nil, color: .systemPink, size: Self.size)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        name = "female"
        zPosition = 20      // ??? why 20?

        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 16))
        physicsBody?.categoryBitMask    = PhysicsCategory.female
        physicsBody?.collisionBitMask   = PhysicsCategory.terrain | PhysicsCategory.world   // ???
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.allowsRotation     = false
        physicsBody?.linearDamping      = 10        // TODO
    }

    // TODO: it's the same for female and mob (maybe player) - move to separate function and/or Base class
    // TODO: maybe implement this with Apple tools?
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
