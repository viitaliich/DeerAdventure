import SpriteKit

class NpcNode: SKSpriteNode {

    var wanderSpeed: CGFloat { 0 }

    private var directionTick = 0
    private var currentDirection = CGVector.zero

    // TODO: maybe do this with Apple tools?
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
            dx: currentDirection.dx / len * wanderSpeed,
            dy: currentDirection.dy / len * wanderSpeed
        )

        if abs(currentDirection.dx) > abs(currentDirection.dy) {
            xScale = currentDirection.dx < 0 ? -1 : 1
        }
    }
}
