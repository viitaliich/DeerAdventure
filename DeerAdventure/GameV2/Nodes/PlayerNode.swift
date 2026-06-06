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
    func updateDirection(_ input: CGVector) {
        // TODO: переключать текстуру/анимацию по направлению
        // Зеркалим спрайт для движения влево
        if abs(input.dx) > abs(input.dy) {
            xScale = input.dx < 0 ? -1 : 1
        }
    }

    func setIdle() {
        // TODO: переключить на idle анимацию
    }
}
