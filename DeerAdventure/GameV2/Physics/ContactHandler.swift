import SpriteKit

enum ContactType {
    case playerFemale
    case other
}

struct ContactHandler {
    static func classify(_ contact: SKPhysicsContact) -> ContactType {
        let masks = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        if masks == PhysicsCategory.player | PhysicsCategory.female {
            return .playerFemale
        }
        return .other
    }

    static func node(in contact: SKPhysicsContact, withCategory category: UInt32) -> SKNode? {
        if contact.bodyA.categoryBitMask == category { return contact.bodyA.node }
        if contact.bodyB.categoryBitMask == category { return contact.bodyB.node }
        return nil
    }
}
