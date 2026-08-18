import SpriteKit

// Water surface for ponds and shallows. Place it in the Scene Editor with
// "Water 1.sks" as a template; the pond takes the size of the node.
//
// The surface warp and the ripple rings are ported from PoolScene.swift in
// SpriteKitShaders by Matt Reagan (MIT). See THIRD_PARTY_NOTICES.md.
class WaterNode: SKSpriteNode {

    // Geometry warp. A finer grid is smoother but costs a warp action per step.
    private static let warpGridSize = 12
    private static let warpDuration: TimeInterval = 0.36

    private var warpPositions: [SIMD2<Float>] = []

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // Level z layout: ground fill and props both sit at 0 and are ordered by
        // their order in the .sks, the deer is at 20, tree canopies at 500.
        // Water goes just above the ground fill — a negative value would hide it
        // under the level background.
        zPosition = 1
        setupShader()
        setupPhysics()
        startSurfaceWarp()
    }

    // Loads the shader through its source string rather than SKShader(fileNamed:).
    // Both end up compiling the same text, but the file-based path swallows
    // compile errors silently, while this one makes SpriteKit report them in the
    // Xcode console. A shader that fails to compile is not obvious on screen —
    // SpriteKit falls back to default shading, so the pond just renders as a
    // plain square of texture.
    private func setupShader() {
        guard let path = Bundle.main.path(forResource: "water", ofType: "fsh"),
              let source = try? String(contentsOfFile: path, encoding: .utf8) else {
            assertionFailure("WaterNode: water.fsh missing from the app bundle")
            return
        }
        shader = SKShader(source: source)
    }

    private func setupPhysics() {
        // Water does not block movement — the body exists only so that entering
        // the pond reports a contact. The rectangle approximates the ellipse the
        // shader draws, hence the inset.
        physicsBody = SKPhysicsBody(
            rectangleOf: CGSize(width: size.width * 0.7, height: size.height * 0.7)
        )
        physicsBody?.isDynamic          = false
        physicsBody?.categoryBitMask    = PhysicsCategory.water
        physicsBody?.collisionBitMask   = PhysicsCategory.none
        physicsBody?.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.female | PhysicsCategory.mob
    }

    // MARK: - Surface warp

    // Continuously warps the sprite mesh towards a new set of random offsets.
    // This is what keeps the water from looking like a looping sine wave.
    private func startSurfaceWarp() {
        warpPositions = gridPositions(warped: false)
        warpGeometry = SKWarpGeometryGrid(columns: Self.warpGridSize, rows: Self.warpGridSize)
        stepSurfaceWarp()
    }

    private func stepSurfaceWarp() {
        let source = warpPositions
        warpPositions = gridPositions(warped: true)

        let grid = SKWarpGeometryGrid(
            columns: Self.warpGridSize,
            rows: Self.warpGridSize,
            sourcePositions: source,
            destinationPositions: warpPositions
        )
        guard let warp = SKAction.warp(to: grid, duration: Self.warpDuration) else { return }
        warp.timingMode = .easeInEaseOut

        run(.sequence([warp, .run { [weak self] in self?.stepSurfaceWarp() }]))
    }

    private func gridPositions(warped: Bool) -> [SIMD2<Float>] {
        let steps = Self.warpGridSize
        let maxOffset = 1.0 / Float(steps + 1) / 2.0

        var points: [SIMD2<Float>] = []
        points.reserveCapacity((steps + 1) * (steps + 1))

        for y in 0...steps {
            for x in 0...steps {
                // Edge vertices stay put, otherwise the pond outline would wobble.
                let isInner = warped && x > 0 && y > 0 && x < steps && y < steps
                func offset() -> Float {
                    isInner ? Float.random(in: -maxOffset / 2 ... maxOffset / 2) : 0
                }
                points.append(
                    SIMD2(Float(x) / Float(steps) + offset(),
                          Float(y) / Float(steps) + offset())
                )
            }
        }
        return points
    }

    // MARK: - Ripples

    // Expanding rings, for hooves entering the water. The point is in this
    // node's coordinate system.
    func splash(at point: CGPoint) {
        for i in 0..<4 {
            let diameter = 16.0 + CGFloat(i + 4) * 8.0
            let duration = 0.80 + 0.28 * TimeInterval(i)

            // zPosition is deliberately left at 0, as in the original: anything
            // floating on the water (leaves in the demo) sits above the rings.
            let ripple = SKShapeNode(ellipseOf: CGSize(width: diameter, height: diameter))
            ripple.position    = point
            ripple.lineWidth   = 4
            ripple.fillColor   = .clear
            ripple.strokeColor = .white
            ripple.blendMode   = .add
            ripple.alpha       = 0.02
            ripple.xScale      = CGFloat.random(in: 0.55...0.65)
            ripple.yScale      = CGFloat.random(in: 0.55...0.65)
            addChild(ripple)

            // Each ring ends at a different scale, so they spread apart.
            let endScale = 0.35 * CGFloat(i + 2)
            let grow = SKAction.scaleX(
                to: endScale + CGFloat.random(in: -0.1...0.1),
                y:  endScale + CGFloat.random(in: -0.1...0.1),
                duration: duration
            )
            grow.timingMode = .easeInEaseOut

            let fade = SKAction.fadeOut(withDuration: duration - 0.1)
            fade.timingMode = .easeInEaseOut

            ripple.run(.sequence([
                .group([
                    .fadeAlpha(to: 0.2, duration: 0.1),
                    grow,
                    .sequence([.wait(forDuration: 0.1), fade])
                ]),
                .removeFromParent()
            ]))
        }
    }

    // True when the point, given in this node's coordinate system, is inside
    // the ellipse the shader draws. Does not assume a centered anchor point.
    func contains(surfacePoint point: CGPoint) -> Bool {
        let center = CGPoint(
            x: (0.5 - anchorPoint.x) * size.width,
            y: (0.5 - anchorPoint.y) * size.height
        )
        let dx = (point.x - center.x) / (size.width  / 2)
        let dy = (point.y - center.y) / (size.height / 2)
        return dx * dx + dy * dy <= 1
    }
}
