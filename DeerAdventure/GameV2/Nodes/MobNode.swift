import SpriteKit

final class MobNode: NpcNode {

    override var wanderSpeed: CGFloat { 35 }

    init() {
        super.init(texture: nil, color: .systemGreen, size: CGSize(width: 20, height: 20))
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
}
