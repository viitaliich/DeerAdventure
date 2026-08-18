import SpriteKit

final class GameSceneV2: SKScene {
    weak var overlayModel: GenesisOverlayModel?

    private static let topScoreDefaultsKey = "GenesisTopScoreV2"

    enum Biome: CaseIterable {
        case forest, snow, ocean

        var title: String {
            switch self {
            case .forest: return "Forest"
            case .snow:   return "Snow"
            case .ocean:  return "Ocean"
            }
        }

        var levelFileName: String {
            switch self {
            case .forest: return "ForestLevel"
            case .snow:   return "SnowLevel"
            case .ocean:  return "OceanLevel"
            }
        }
    }

    private enum State { case menu, playing, paused, gameOver }

    // MARK: - Nodes

    private let worldNode    = SKNode()
    private let cameraNode   = SKCameraNode()
    private var levelNode: SKNode?

    // MARK: - Entities

    private var playerNode: PlayerNode?
    private var females: [FemaleNode] = []
    private var mobs: [MobNode] = []
    private var waters: [WaterNode] = []

    // MARK: - State

    private var state: State = .menu
    private var selectedBiome: Biome = .forest

    private var population: Int = 2
    private var breedingBirthMultiplier: Int = 1
    private var topScore: Int = UserDefaults.standard.integer(forKey: GameSceneV2.topScoreDefaultsKey)
    private var timeRemaining: Int = GameBalance.gameDuration

    private var stateTick: Int = 0
    private var accumulator: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private let fixedStep: TimeInterval = 1.0 / 60.0

    private var inputVector = CGVector.zero

    private let soundManager = SoundManager()

    deinit { soundManager.stopAll() }

    // MARK: - Setup

    // Scene entry point. Lifecycle method.
    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        backgroundColor = .black
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        addChild(worldNode)
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.setScale(0.6)    // zoom

        startGame(with: .forest)
    }

    // MARK: - Game lifecycle

    func startGame(with biome: Biome) {
        // TODO: split functionality to smaller methods.
        selectedBiome = biome
        state = .playing
        stateTick = 0
        population = 2
        timeRemaining = GameBalance.gameDuration
        inputVector = .zero

        clearWorld()
        loadLevel(biome)
        spawnInitialEntities()

        // TODO: maybe rewrite state with GameplayKit?
        overlayModel?.isPlaying = true
        overlayModel?.isGameOver = false
        overlayModel?.isPaused = false
        overlayModel?.biomeTitle = biome.title

        soundManager.playLoop("theme")
        soundManager.playOneShot("start", volume: 0.95)
        updateHUD()
    }

    private func clearWorld() {
        levelNode?.removeFromParent()
        levelNode = nil
        females.removeAll()
        mobs.removeAll()
        waters.removeAll()
        playerNode = nil
    }

    private func loadLevel(_ biome: Biome) {
        guard let scene = SKScene(fileNamed: biome.levelFileName) else {
            // Уровень ещё не создан — ставим пустой placeholder
            let placeholder = SKNode()
            worldNode.addChild(placeholder)
            levelNode = placeholder
            return
        }

        let container = SKNode()
        for child in scene.children {
            child.removeFromParent()
            container.addChild(child)
        }
        worldNode.addChild(container)
        levelNode = container
    }

    // Ponds sit inside SKReferenceNodes, which fill themselves in when they are
    // added to the scene, so the tree is not walked at load time. Collected once
    // on first use and cached for the rest of the level.
    private func collectWaterNodes(in node: SKNode) {
        for child in node.children {
            if let water = child as? WaterNode { waters.append(water) }
            collectWaterNodes(in: child)
        }
    }

    private func spawnInitialEntities() {
        let spawnPos = spawnPoint(named: "playerSpawn") ?? CGPoint(x: 200, y: 200)  // TODO: maybe remove default values?
        let femalePos = spawnPoint(named: "femaleSpawn") ?? CGPoint(x: 250, y: 250)

        let p = PlayerNode()
        p.position = spawnPos
        worldNode.addChild(p)
        playerNode = p

        let f = FemaleNode()
        f.position = femalePos
        worldNode.addChild(f)
        females.append(f)

        cameraNode.position = spawnPos
    }

    private func spawnPoint(named name: String) -> CGPoint? {
        levelNode?.childNode(withName: name)?.position
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        let delta: TimeInterval
        if lastUpdateTime == 0 {
            delta = fixedStep
        } else {
            delta = min(0.1, currentTime - lastUpdateTime)
        }
        lastUpdateTime = currentTime
        accumulator += delta

        while accumulator >= fixedStep {
            fixedUpdate()
            accumulator -= fixedStep
        }
    }

    private func fixedUpdate() {
        guard state == .playing else { return }
        stateTick += 1

        updatePlayerMovement()
        updateEntityMovement()
        updateCamera()

        // Ripples while wading. Every tick would bury the surface in rings.
        if stateTick % 18 == 0 { updateWading() }

        if stateTick % 60 == 0 {
            timeRemaining -= 1
            if timeRemaining <= 0 { showGameOver() }
        }

        updateHUD()
    }

    private func updatePlayerMovement() {
        playerNode?.move(input: inputVector)
    }

    private func updateEntityMovement() {
        for female in females {
            female.updateAI()
        }
        for mob in mobs {
            mob.updateAI()
        }
    }

    private func updateWading() {
        guard let player = playerNode, inputVector != .zero else { return }

        if waters.isEmpty, let level = levelNode { collectWaterNodes(in: level) }

        for water in waters {
            let pointInWater = water.convert(player.position, from: worldNode)
            guard water.contains(surfacePoint: pointInWater) else { continue }
            water.splash(at: pointInWater)
        }
    }

    private func updateCamera() {
        guard let player = playerNode else { return }
        cameraNode.position = clampedPosition(player.position)
    }

    private func clampedPosition(_ pos: CGPoint) -> CGPoint {
        // Будет уточнено когда будут известны размеры уровней
        pos
    }

    // MARK: - Breeding

    private func handleBreeding(female: FemaleNode) {
        guard female.canBreed else { return }
        female.canBreed = false

        let baseBorn = Int.random(in: GameBalance.breedingBaseCount)
        let born = baseBorn * breedingBirthMultiplier

        for _ in 0..<born {
            let mob = MobNode()
            mob.position = female.position
            worldNode.addChild(mob)
            mobs.append(mob)
        }
        population += born

        let femaleCount = Int.random(in: 1...4)
        for _ in 0..<femaleCount {
            let f = FemaleNode()
            f.position = randomSpawnPosition()
            worldNode.addChild(f)
            females.append(f)
        }

        soundManager.playOneShot("breed", volume: 0.85)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func randomSpawnPosition() -> CGPoint {
        // Placeholder — уточним когда будут реальные размеры уровня
        CGPoint(
            x: CGFloat.random(in: 100...1900),
            y: CGFloat.random(in: 100...1900)
        )
    }

    // MARK: - Game over

    private func showGameOver() {
        updateTopScoreIfNeeded()
        state = .gameOver
        inputVector = .zero
        overlayModel?.isGameOver = true
        overlayModel?.isPaused = false
        overlayModel?.gameOverText = "GAME OVER\nPopulation: \(population)"
        overlayModel?.topScoreText = "Top Score: \(topScore)"
        soundManager.stopAllLoops()
        soundManager.playOneShot("gameover", volume: 1.0)
    }

    private func updateTopScoreIfNeeded() {
        let current = population
        guard current > topScore else { return }
        topScore = current
        UserDefaults.standard.set(topScore, forKey: Self.topScoreDefaultsKey)
    }

    // MARK: - HUD

    private func updateHUD() {
        overlayModel?.populationText = "Population: \(population)"
        let minutes = max(0, timeRemaining) / 60
        let seconds = max(0, timeRemaining) % 60
        overlayModel?.timerText = String(format: "Time: %d:%02d", minutes, seconds)
        overlayModel?.breedingMultiplierText = "x\(breedingBirthMultiplier)"
        overlayModel?.topScoreText = "Top Score: \(topScore)"
    }

    // MARK: - Public interface (same as GenesisGameScene)

    func setInputVector(_ vector: CGVector) {
        guard state == .playing else { return }
        inputVector = vector
    }

    func pauseGameFromOverlay() {
        guard state == .playing else { return }
        state = .paused
        inputVector = .zero
        overlayModel?.isPaused = true
        soundManager.playLoop("menutheme")
    }

    func resumeGameFromOverlay() {
        guard state == .paused else { return }
        state = .playing
        inputVector = .zero
        overlayModel?.isPaused = false
        soundManager.playLoop("theme")
    }

    func restartGameFromOverlay() {
        guard state == .gameOver else { return }
        startGame(with: selectedBiome)
    }

    func setBreedingBirthMultiplier(_ value: Int) {
        breedingBirthMultiplier = min(GameBalance.maxBreedingMultiplier, max(1, value))
        overlayModel?.breedingMultiplierText = "x\(breedingBirthMultiplier)"
    }
}

// MARK: - SKPhysicsContactDelegate

extension GameSceneV2: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        switch ContactHandler.classify(contact) {
        case .playerFemale:
            guard let femaleNode = ContactHandler.node(in: contact, withCategory: PhysicsCategory.female) as? FemaleNode else { return }
            handleBreeding(female: femaleNode)

        case .playerWater:
            guard let water = ContactHandler.node(in: contact, withCategory: PhysicsCategory.water) as? WaterNode,
                  let player = playerNode else { return }
            water.splash(at: water.convert(player.position, from: worldNode))

        case .other:
            break
        }
    }
}
