import SpriteKit

class BushNode: SKSpriteNode {

    required init?(coder: NSCoder) {
        super.init(coder: coder)
//        setupPhysics()
    }

    private func setupPhysics() {
        physicsBody = makeBody(insetLeft: 0.40, top: 0.55, right: 0.50, bottom: 0.20)
        physicsBody?.isDynamic          = false
        physicsBody?.categoryBitMask    = PhysicsCategory.terrain
        physicsBody?.collisionBitMask   = PhysicsCategory.player | PhysicsCategory.female | PhysicsCategory.mob
        physicsBody?.contactTestBitMask = PhysicsCategory.none
    }

    // Insets as fractions of the node's rendered size (0.0 ... 1.0).
    // Example: top: 0.6 means the body starts 60% down from the top edge.
    private func makeBody(insetLeft left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) -> SKPhysicsBody {
        let s = size
        let bodyW = s.width  * (1 - left - right)
        let bodyH = s.height * (1 - top - bottom)
        let centerX = s.width  * (left - right) / 2
        let centerY = s.height * (bottom - top) / 2
        return SKPhysicsBody(
            rectangleOf: CGSize(width: bodyW, height: bodyH),
            center: CGPoint(x: centerX, y: centerY)
        )
    }
}
