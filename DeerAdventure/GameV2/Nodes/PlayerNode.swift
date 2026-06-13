import SpriteKit

final class PlayerNode: SKSpriteNode {

    private static let size = CGSize(width: 24, height: 24)

    init() {
        super.init(texture: nil, color: .systemBlue, size: Self.size)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        name = "player"
        zPosition = 20

        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 16))
        physicsBody?.categoryBitMask    = PhysicsCategory.player
        physicsBody?.collisionBitMask   = PhysicsCategory.terrain | PhysicsCategory.world
        physicsBody?.contactTestBitMask = PhysicsCategory.female
        physicsBody?.allowsRotation     = false
        physicsBody?.linearDamping      = 10
    }

    // TODO: maybe make texture management in Base class?
    func move(input: CGVector) {
        let length = hypot(input.dx, input.dy)
        guard length > 0.0001 else {
            physicsBody?.velocity = .zero
            setIdle()
            return
        }
        physicsBody?.velocity = CGVector(
            dx: input.dx / length * 90,
            dy: input.dy / length * 90
        )
        updateDirection(input)
    }

    private func updateDirection(_ input: CGVector) {
        // TODO: переключать текстуру/анимацию по направлению
        if abs(input.dx) > abs(input.dy) {
            xScale = input.dx < 0 ? -1 : 1
        }
    }

    private func setIdle() {
        // TODO: переключить на idle анимацию
    }
}
