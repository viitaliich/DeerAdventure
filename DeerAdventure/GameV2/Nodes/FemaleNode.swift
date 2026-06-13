import SpriteKit

final class FemaleNode: NpcNode {

    override var wanderSpeed: CGFloat { 45 }

    var canBreed = true

    init() {
        super.init(texture: nil, color: .systemPink, size: CGSize(width: 24, height: 24))
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        name = "female"
        zPosition = 20

        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 16))
        physicsBody?.categoryBitMask    = PhysicsCategory.female
        physicsBody?.collisionBitMask   = PhysicsCategory.terrain | PhysicsCategory.world
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.allowsRotation     = false
        physicsBody?.linearDamping      = 10
    }
}
