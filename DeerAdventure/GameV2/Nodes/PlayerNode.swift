import SpriteKit

final class PlayerNode: SKSpriteNode {

    private static let visualSize  = CGSize(width: 48, height: 48)
    private static let physicsSize = CGSize(width: 32, height: 32)
    private static let atlas       = SKTextureAtlas(named: "player")

    private enum Direction { case front, back, side }
    private var direction: Direction = .front
    private var isMoving = false

    private lazy var frontFrames: [SKTexture] = Self.frames(prefix: "Deer_walk_front-walk_toward_camera")
    private lazy var backFrames:  [SKTexture] = Self.frames(prefix: "walk_back")
    private lazy var sideFrames:  [SKTexture] = Self.frames(prefix: "frame")

    private static func frames(prefix: String) -> [SKTexture] {
        atlas.textureNames
            .filter { $0.hasPrefix(prefix) }
            .sorted()
            .map { atlas.textureNamed($0) }
    }

    init() {
        let texture = Self.atlas.textureNamed("walk_front_1")
        super.init(texture: texture, color: .clear, size: Self.visualSize)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        name = "player"
        zPosition = 20

        physicsBody = SKPhysicsBody(rectangleOf: Self.physicsSize)
        physicsBody?.categoryBitMask    = PhysicsCategory.player
        physicsBody?.collisionBitMask   = PhysicsCategory.terrain | PhysicsCategory.world
        physicsBody?.contactTestBitMask = PhysicsCategory.female
        physicsBody?.allowsRotation     = false
        physicsBody?.linearDamping      = 10
    }

    func move(input: CGVector) {
        let length = hypot(input.dx, input.dy)
        guard length > 0.0001 else {
            physicsBody?.velocity = .zero
            if isMoving { setIdle(); isMoving = false }
            return
        }
        physicsBody?.velocity = CGVector(dx: input.dx / length * 90, dy: input.dy / length * 90)
        updateDirectionAndAnimation(input)
        isMoving = true
    }

    private func updateDirectionAndAnimation(_ input: CGVector) {
        let newDir: Direction
        if abs(input.dx) > abs(input.dy) {
            newDir = .side
            xScale = input.dx > 0 ? -1 : 1
        } else {
            newDir = input.dy > 0 ? .back : .front
            xScale = 1
        }

        guard newDir != direction else { return }
        direction = newDir
        playWalk()
    }

    // ??? maybe use SKAction.animateWithTextures method?
    private func playWalk() {
        let f = currentFrames
        guard !f.isEmpty else { return }
        run(.repeatForever(.animate(with: f, timePerFrame: 0.12)), withKey: "anim")
    }

    private func setIdle() {
        removeAction(forKey: "anim")
        texture = currentFrames.first
    }

    private var currentFrames: [SKTexture] {
        switch direction {
        case .front: return frontFrames
        case .back:  return backFrames
        case .side:  return sideFrames
        }
    }
}
