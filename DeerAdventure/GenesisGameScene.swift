import SpriteKit
import UIKit
import AVFoundation

final class GenesisGameScene: SKScene {
    weak var overlayModel: GenesisOverlayModel?
    private static let topScoreDefaultsKey = "GenesisTopScore"
    private let isMainMenuDisabled = true

    enum Biome: CaseIterable {
        case forest, snow, ocean

        var title: String {
            switch self {
            case .forest: return "Forest"
            case .snow: return "Snow"
            case .ocean: return "Ocean"
            }
        }

        var levelImageName: String {
            switch self {
            case .forest: return "genesis_level_forest_3"
            case .snow: return "genesis_level_snow"
            case .ocean: return "genesis_level_ocean"
            }
        }
    }

    private enum State { case menu, playing, paused, gameOver }
    private enum GroundTile { case grassGround, grass, rock, water, snow, ice, flower, snowRock, voidTile }
    private enum OverlayTile { case none, tree, snowTree, torch }

    private struct SpawnPoint { let x: CGFloat; let y: CGFloat }

    private final class Mob {
        enum Kind { case player, female, forestMob, oceanMob, predator }

        let kind: Kind
        let node: SKSpriteNode
        var x: CGFloat
        var y: CGFloat
        var xa: Int = 0
        var ya: Int = 0
        var dir: Int = 0
        var walking = false
        var anim = 0
        var health = 100
        var canSpawnChild = true

        init(kind: Kind, x: CGFloat, y: CGFloat, texture: SKTexture) {
            self.kind = kind
            self.x = x
            self.y = y
            self.node = SKSpriteNode(texture: texture)
            self.node.anchorPoint = CGPoint(x: 0, y: 0)
            self.node.size = CGSize(width: 16, height: 16)
            self.node.zPosition = 20
            self.node.texture?.filteringMode = .nearest
        }
    }

    private var state: State = .menu
    private var selectedBiome: Biome = .forest

    private let worldNode = SKNode()
    private let entityNode = SKNode()
    private let topOverlayNode = SKNode()
    private let hudNode = SKNode()
    private let cameraNode2D = SKCameraNode()
    private let gameplayZoom: CGFloat = 0.6
    private let deerMoveSpeed: CGFloat = 1.5

    private let tileSize: CGFloat = 16
    private var levelWidth = 128
    private var levelHeight = 128
    private var worldSize = CGSize(width: 2048, height: 2048)
    private var levelPixels: [UInt32] = []
    private var grassNoise: [Int] = []

    private var stateTick: Int = 0
    private var waterAnimTick: Int = 0

    private var population: Double = 2
    private var breedingBirthMultiplier: Int = 1
    private var topScore: Int = UserDefaults.standard.integer(forKey: GenesisGameScene.topScoreDefaultsKey)
    private var timeRemaining: Int = 5 * 60
//    private var timeRemaining: Int = 5
    

    private var player: Mob?
    private var females: [Mob] = []
    private var mobs: [Mob] = []

    private var inputVector = CGVector.zero

    private var accumulator: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private let fixedStep: TimeInterval = 1.0 / 60.0

    private var populationLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var timerLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var backLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var menuTitleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var biomeLabels: [Biome: SKLabelNode] = [:]

    private var spriteSheet: CGImage?
    private var textureCache: [String: SKTexture] = [:]
    private var tileImageCache: [String: CGImage] = [:]

    private final class SoundManager {
        private var loopingPlayers: [String: AVAudioPlayer] = [:]

        func playLoop(_ name: String) {
            stopAllLoops()
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = 0.55
                player.prepareToPlay()
                player.play()
                loopingPlayers[name] = player
            } catch {
                print("[Sound] loop error for \(name): \(error)")
            }
        }

        func playOneShot(_ name: String, volume: Float = 0.9) {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = 0
                player.volume = volume
                player.prepareToPlay()
                player.play()
                // Держим временно в словаре, чтобы не деаллоцировался до окончания.
                let key = "oneshot_\(name)_\(Date().timeIntervalSince1970)"
                loopingPlayers[key] = player
                DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) { [weak self] in
                    self?.loopingPlayers.removeValue(forKey: key)
                }
            } catch {
                print("[Sound] one-shot error for \(name): \(error)")
            }
        }

        func stopAllLoops() {
            for (_, player) in loopingPlayers {
                if player.numberOfLoops != 0 {
                    player.stop()
                }
            }
            loopingPlayers = loopingPlayers.filter { $0.value.numberOfLoops == 0 }
        }

        func stopAll() {
            for (_, player) in loopingPlayers { player.stop() }
            loopingPlayers.removeAll()
        }
    }

    private let soundManager = SoundManager()

    private func triggerBreedingHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }

    deinit {
        soundManager.stopAll()
    }

    override func didMove(to view: SKView) {
        scaleMode = .resizeFill
        backgroundColor = .black

        if camera == nil {
            addChild(worldNode)
            worldNode.addChild(entityNode)
            worldNode.addChild(topOverlayNode)
            addChild(cameraNode2D)
            camera = cameraNode2D
            cameraNode2D.addChild(hudNode)
        }

        setCameraZoom(1.0)

        loadSheetIfNeeded()
        setupHUD()
        if isMainMenuDisabled {
            startGame(with: .forest)
        } else {
            showMenu()
        }
    }

    private func setCameraZoom(_ zoom: CGFloat) {
        cameraNode2D.setScale(zoom)
        hudNode.setScale(1.0 / zoom)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        populationLabel.position = CGPoint(x: size.width * 0.45, y: size.height * 0.43)
        timerLabel.position = CGPoint(x: 0, y: -size.height * 0.44)
        backLabel.position = CGPoint(x: -size.width * 0.45, y: -size.height * 0.44)
    }

    private func setupHUD() {
        populationLabel.fontSize = 20
        populationLabel.horizontalAlignmentMode = .right
        populationLabel.verticalAlignmentMode = .center
        hudNode.addChild(populationLabel)

        timerLabel.fontSize = 20
        timerLabel.horizontalAlignmentMode = .center
        timerLabel.verticalAlignmentMode = .center
        hudNode.addChild(timerLabel)

        backLabel.text = "← Menu"
        backLabel.fontSize = 22
        backLabel.horizontalAlignmentMode = .left
        backLabel.verticalAlignmentMode = .center
        backLabel.zPosition = 100
        hudNode.addChild(backLabel)

        didChangeSize(size)

        // Внутриигровой HUD переносим в SwiftUI (iOS-стиль), SpriteKit-лейблы скрываем.
        populationLabel.isHidden = true
        timerLabel.isHidden = true
        backLabel.isHidden = true
    }

    private func showMenu() {
        if isMainMenuDisabled {
            startGame(with: .forest)
            return
        }

        state = .menu
        setCameraZoom(1.0)
        clearWorld()
        backLabel.isHidden = true
        inputVector = .zero
        overlayModel?.isPlaying = false
        overlayModel?.isGameOver = false
        overlayModel?.isPaused = false
        overlayModel?.populationText = ""
        overlayModel?.timerText = ""
        overlayModel?.breedingMultiplierText = breedingMultiplierDisplayText
        overlayModel?.topScoreText = "Top Score: \(topScore)"
        overlayModel?.biomeTitle = ""
        overlayModel?.gameOverText = ""

        soundManager.playLoop("menutheme")

        cameraNode2D.children.filter { $0 !== hudNode }.forEach { $0.removeFromParent() }

        menuTitleLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        menuTitleLabel.text = "GENESIS"
        menuTitleLabel.fontSize = 54
        menuTitleLabel.position = CGPoint(x: 0, y: 120)
        cameraNode2D.addChild(menuTitleLabel)

        biomeLabels.removeAll()
        for (index, biome) in Biome.allCases.enumerated() {
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.text = biome == selectedBiome ? "> \(biome.title) <" : biome.title
            label.fontSize = 36
            label.fontColor = .white
            label.position = CGPoint(x: 0, y: 30 - CGFloat(index) * 52)
            label.name = "biome_\(biome.title)"
            cameraNode2D.addChild(label)
            biomeLabels[biome] = label
        }

        let hint = SKLabelNode(fontNamed: "AvenirNext-Regular")
        hint.text = "Tap biome to start"
        hint.fontSize = 22
        hint.alpha = 0.9
        hint.position = CGPoint(x: 0, y: -170)
        cameraNode2D.addChild(hint)

        populationLabel.text = ""
        timerLabel.text = ""
    }

    private func startGame(with biome: Biome) {
        selectedBiome = biome
        state = .playing
        setCameraZoom(gameplayZoom)
        inputVector = .zero
        stateTick = 0
        waterAnimTick = 0
        population = 2
        timeRemaining = 30
//        timeRemaining = 5

        cameraNode2D.children.filter { $0 !== hudNode }.forEach { $0.removeFromParent() }
        clearWorld()
        buildWorld(for: biome)
        spawnInitialEntities(for: biome)
        backLabel.isHidden = true
        overlayModel?.isPlaying = true
        overlayModel?.isGameOver = false
        overlayModel?.isPaused = false
        overlayModel?.biomeTitle = biome.title

        soundManager.playLoop("theme")
        soundManager.playOneShot("start", volume: 0.95)
        updateHUD()
    }

    private func clearWorld() {
        worldNode.removeAllChildren()
        worldNode.addChild(entityNode)
        worldNode.addChild(topOverlayNode)
        entityNode.removeAllChildren()
        topOverlayNode.removeAllChildren()
        females.removeAll()
        mobs.removeAll()
        player = nil
    }

    private func buildWorld(for biome: Biome) {
        guard let levelImage = UIImage(named: biome.levelImageName)?.cgImage else { return }

        let (w, h, pixels) = pixelsFromImage(levelImage)
        levelWidth = w
        levelHeight = h
        worldSize = CGSize(width: CGFloat(w) * tileSize, height: CGFloat(h) * tileSize)
        levelPixels = pixels
        grassNoise = (0..<(w * h)).map { _ in Int.random(in: 0...7) }

        let baseTexture = renderLayer(includeTreeTops: false, waterFrame: 0)
        let topTexture = renderLayer(includeTreeTops: true, waterFrame: 0)

        let base = SKSpriteNode(texture: baseTexture)
        base.anchorPoint = CGPoint(x: 0, y: 0)
        base.position = .zero
        base.size = worldSize
        base.zPosition = 0
        base.texture?.filteringMode = .nearest
        worldNode.addChild(base)

        let top = SKSpriteNode(texture: topTexture)
        top.anchorPoint = CGPoint(x: 0, y: 0)
        top.position = .zero
        top.size = worldSize
        top.zPosition = 40
        top.texture?.filteringMode = .nearest
        topOverlayNode.addChild(top)
    }

    private func spawnInitialEntities(for biome: Biome) {
        let playerSpawn: SpawnPoint
        let femaleSpawn: SpawnPoint

        switch biome {
        case .forest:
            // На (10,100) в текущей системе координат игрок оказывается внутри дерева и не может сделать шаг.
            // Сдвиг на 1 тайл влево даёт свободную стартовую позицию.
            playerSpawn = .init(x: 9 * 16, y: 100 * 16)
            femaleSpawn = .init(x: 21 * 16, y: 102 * 16)
        case .snow:
            playerSpawn = .init(x: 80 * 16, y: 100 * 16)
            femaleSpawn = .init(x: 105 * 16, y: 94 * 16)
        case .ocean:
            playerSpawn = .init(x: 54 * 16, y: 23 * 16)
            femaleSpawn = .init(x: 66 * 16, y: 26 * 16)
        }

        let p = Mob(kind: .player, x: playerSpawn.x, y: playerSpawn.y, texture: mobTexture(kind: .player, dir: 0, walking: false, anim: 0))
        entityNode.addChild(p.node)
        player = p

        let f = Mob(kind: .female, x: femaleSpawn.x, y: femaleSpawn.y, texture: mobTexture(kind: .female, dir: 0, walking: false, anim: 0))
        entityNode.addChild(f.node)
        females.append(f)

        syncMobNode(p)
        syncMobNode(f)
        cameraNode2D.position = CGPoint(x: p.x + 8, y: p.y + 8)
    }

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
        waterAnimTick += 1

        updatePlayer()
        updateFemalesAndMobs()
        updateBreeding()
        updatePopulation()
        updateTopScoreIfNeeded()

        if stateTick % 60 == 0 {
            timeRemaining -= 1
            if timeRemaining <= 0 {
                showGameOver()
            }
        }

        // Полный пересчёт всей карты каждые 48 тиков даёт фризы и рост памяти на iOS.
        // Оставляем статичный water frame для стабильности.

        updateHUD()
    }

    private func updatePlayer() {
        guard let player else { return }
        let (xa, ya) = normalizedDirection(x: CGFloat(inputVector.dx), y: CGFloat(inputVector.dy))
        move(mob: player, xa: xa, ya: ya)
        syncMobNode(player)
        cameraNode2D.position = clampedCameraPosition(x: player.x + 8, y: player.y + 8)
    }

    private func clampedCameraPosition(x: CGFloat, y: CGFloat) -> CGPoint {
        // Ограничиваем камеру границами мира, чтобы не показывать чёрные полосы за пределами карты.
        let halfVisibleWidth = (size.width * cameraNode2D.xScale) * 0.5
        let halfVisibleHeight = (size.height * cameraNode2D.yScale) * 0.5

        let minX = halfVisibleWidth
        let maxX = worldSize.width - halfVisibleWidth
        let minY = halfVisibleHeight
        let maxY = worldSize.height - halfVisibleHeight

        let clampedX: CGFloat
        if minX > maxX {
            clampedX = worldSize.width * 0.5
        } else {
            clampedX = min(max(x, minX), maxX)
        }

        let clampedY: CGFloat
        if minY > maxY {
            clampedY = worldSize.height * 0.5
        } else {
            clampedY = min(max(y, minY), maxY)
        }

        return CGPoint(x: clampedX, y: clampedY)
    }

    private func updateFemalesAndMobs() {
        for female in females {
            if Int.random(in: 0..<40) == 0 {
                female.xa = Int.random(in: -1...1)
                female.ya = Int.random(in: -1...1)
            }
            let (fx, fy) = normalizedDirection(x: CGFloat(female.xa), y: CGFloat(female.ya))
            move(mob: female, xa: fx, ya: fy)
            syncMobNode(female)
        }

        for mob in mobs {
            if Int.random(in: 0..<40) == 0 {
                mob.xa = Int.random(in: -1...1)
                mob.ya = Int.random(in: -1...1)
            }
            let (mx, my) = normalizedDirection(x: CGFloat(mob.xa), y: CGFloat(mob.ya))
            move(mob: mob, xa: mx, ya: my)
            syncMobNode(mob)
        }
    }

    private func normalizedDirection(x: CGFloat, y: CGFloat) -> (CGFloat, CGFloat) {
        let length = hypot(x, y)
        guard length > 0.0001 else { return (0, 0) }
        return (x / length, y / length)
    }

    private func updateBreeding() {
        guard let player else { return }

        for female in females where female.canSpawnChild {
            if (Int(player.x) >> 4) == (Int(female.x) >> 4), (Int(player.y) >> 4) == (Int(female.y) >> 4) {
                let baseBorn = Int.random(in: 1...4)
                let born = baseBorn * breedingBirthMultiplier
                for _ in 0..<born {
                    let kind: Mob.Kind = (selectedBiome == .ocean) ? .oceanMob : .forestMob
                    let m = Mob(kind: kind, x: player.x, y: player.y, texture: mobTexture(kind: kind, dir: 0, walking: false, anim: 0))
                    entityNode.addChild(m.node)
                    mobs.append(m)
                    syncMobNode(m)
                }
                population += Double(born)
                female.canSpawnChild = false
                soundManager.playOneShot("breed", volume: 0.85)
                triggerBreedingHaptic()

                let femaleCount: Int
                switch selectedBiome {
                case .ocean: femaleCount = Int.random(in: 1...2)
                case .snow: femaleCount = Int.random(in: 2...6)
                case .forest: femaleCount = Int.random(in: 1...4)
                }

                for _ in 0..<femaleCount {
                    let sp = spawnFemalePoint()
                    let f = Mob(kind: .female, x: sp.x, y: sp.y, texture: mobTexture(kind: .female, dir: 0, walking: false, anim: 0))
                    entityNode.addChild(f.node)
                    females.append(f)
                    syncMobNode(f)
                }
                break
            }
        }
    }

    private func updatePopulation() {
        let pop = Int(floor(population))
        if pop > 0, pop % 800 == 0, Int.random(in: 0..<6) == 0 {
            let kind: Mob.Kind = (selectedBiome == .ocean) ? .oceanMob : .forestMob
            let sp = spawnGenericMobPoint()
            let m = Mob(kind: kind, x: sp.x, y: sp.y, texture: mobTexture(kind: kind, dir: 0, walking: false, anim: 0))
            entityNode.addChild(m.node)
            mobs.append(m)
            syncMobNode(m)

            if selectedBiome == .forest, Int.random(in: 0...4) == 0 {
                let fsp = spawnFemalePoint()
                let f = Mob(kind: .female, x: fsp.x, y: fsp.y, texture: mobTexture(kind: .female, dir: 0, walking: false, anim: 0))
                entityNode.addChild(f.node)
                females.append(f)
                syncMobNode(f)
                population += 1
            }
        }
    }

    private func showGameOver() {
        updateTopScoreIfNeeded()
        state = .gameOver
        inputVector = .zero
        backLabel.isHidden = true
        overlayModel?.isGameOver = true
        overlayModel?.isPaused = false
        overlayModel?.gameOverText = "GAME OVER\nPopulation: \(Int(population))"
        overlayModel?.topScoreText = "Top Score: \(topScore)"
        soundManager.stopAllLoops()
        soundManager.playOneShot("gameover", volume: 1.0)
    }

    private func updateHUD() {
        populationLabel.text = "Population: \(Int(floor(population)))"
        let minutes = max(0, timeRemaining) / 60
        let seconds = max(0, timeRemaining) % 60
        timerLabel.text = String(format: "Time: %d:%02d", minutes, seconds)

        let textColor: SKColor = (selectedBiome == .snow) ? .black : .white
        populationLabel.fontColor = textColor
        timerLabel.fontColor = textColor
        backLabel.fontColor = textColor

        overlayModel?.populationText = populationLabel.text ?? ""
        overlayModel?.timerText = timerLabel.text ?? ""
        overlayModel?.breedingMultiplierText = breedingMultiplierDisplayText
        overlayModel?.topScoreText = "Top Score: \(topScore)"
    }

    private func updateTopScoreIfNeeded() {
        let currentPopulation = Int(floor(population))
        guard currentPopulation > topScore else { return }
        topScore = currentPopulation
        UserDefaults.standard.set(topScore, forKey: Self.topScoreDefaultsKey)
    }

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

    func returnToMenuFromOverlay() {
        showMenu()
    }

    func restartGameFromOverlay() {
        guard state == .gameOver else { return }
        startGame(with: selectedBiome)
    }

    private var breedingMultiplierDisplayText: String {
        "x\(breedingBirthMultiplier)"
    }

    private func normalizeBreedingBirthMultiplier(_ value: Int) -> Int {
        min(100, max(1, value))
    }

    func setBreedingBirthMultiplier(_ value: Int) {
        breedingBirthMultiplier = normalizeBreedingBirthMultiplier(value)
        overlayModel?.breedingMultiplierText = breedingMultiplierDisplayText
    }

    private func move(mob: Mob, xa: CGFloat, ya: CGFloat) {
        var stepX = xa * deerMoveSpeed
        var stepY = ya * deerMoveSpeed

        let absX = abs(xa)
        let absY = abs(ya)
        if absX > 0.0001 || absY > 0.0001 {
            if absX >= absY {
                mob.dir = xa >= 0 ? 1 : 3
            } else {
                mob.dir = ya >= 0 ? 2 : 0
            }
        }

        mob.walking = (xa != 0 || ya != 0)
        mob.anim += 1

        if !collisionFor(mob: mob, xa: stepX, ya: stepY) && !collisionForOverlay(mob: mob, xa: stepX, ya: stepY) {
            mob.x += stepX
            mob.y += stepY
        }
    }

    private func collisionFor(mob: Mob, xa: CGFloat, ya: CGFloat) -> Bool {
        for i in 0..<4 {
            let xt = (Int(mob.x + xa) + ((i % 2) * 2) * 5) >> 4
            let worldTileY = (Int(mob.y + ya) + ((i / 2) * 2 - 4) * 2) >> 4
            let mapTileY = levelHeight - 1 - worldTileY
            if solid(tileAt: xt, y: mapTileY + 1) { return true }
        }
        return false
    }

    private func collisionForOverlay(mob: Mob, xa: CGFloat, ya: CGFloat) -> Bool {
        for i in 0..<4 {
            let xt = (Int(mob.x + xa) + ((i % 2) * 2 - 1) * 4) >> 4
            let worldTileY = (Int(mob.y + ya) + ((i / 2) * 2 - 1) * 4) >> 4
            let mapTileY = levelHeight - 1 - worldTileY
            if solidOverlay(tileAt: xt, y: mapTileY) { return true }
        }
        return false
    }

    private func solid(tileAt x: Int, y: Int) -> Bool {
        switch groundTileAt(x: x, y: y) {
        case .rock, .water, .ice, .snowRock:
            return true
        default:
            return false
        }
    }

    private func solidOverlay(tileAt x: Int, y: Int) -> Bool {
        switch overlayTileAt(x: x, y: y) {
        case .tree, .snowTree:
            return true
        default:
            return false
        }
    }

    private func levelColorAt(x: Int, y: Int) -> UInt32 {
        return levelPixels[x + y * levelWidth]
    }

    private func groundTileAt(x: Int, y: Int) -> GroundTile {
        if selectedBiome == .snow, (x < 0 || x >= levelWidth || y < 0 || y >= levelHeight) { return .ice }
        if x < 0 || x >= levelWidth || y < 0 || y >= levelHeight { return .voidTile }

        let col = levelColorAt(x: x, y: y)
        let grassBit = grassNoise[x + y * levelWidth]

        if col == 0xFFFFFFFF, selectedBiome == .snow { return .snow }
        if (col == 0xFFFFFFFF || col == 0xFFFFFF00), grassBit == 0, selectedBiome != .snow { return .grass }
        if col == 0xFF156B20, selectedBiome == .snow { return .snow }
        if col == 0xFFFFFF00, selectedBiome == .snow { return .snow }
        if col == 0xFF44C4FF, selectedBiome == .snow { return .snowRock }
        if col == 0xFFFFFFFF || col == 0xFF156B20 || col == 0xFFFFFF00 { return .grassGround }
        if col == 0xFF44C4FF { return .rock }
        if col == 0xFF3A5EFF { return .water }
        if col == 0xFFB5C2FF { return .ice }
        if col == 0xFF00FF04 { return .flower }
        return .voidTile
    }

    private func overlayTileAt(x: Int, y: Int) -> OverlayTile {
        if selectedBiome == .forest, (x < 0 || x >= levelWidth || y < 0 || y >= levelHeight) { return .tree }
        if x < 0 || x >= levelWidth || y < 0 || y >= levelHeight { return .none }

        let col = levelColorAt(x: x, y: y)
        if col == 0xFF156B20, selectedBiome == .snow { return .snowTree }
        if col == 0xFF156B20 { return .tree }
        if col == 0xFFFFFF00 { return .torch }
        return .none
    }

    private func refreshWorldWaterFrame() {
        guard state == .playing else { return }
        topOverlayNode.removeAllChildren()
        worldNode.children.filter { $0.zPosition == 0 }.forEach { $0.removeFromParent() }

        let frame = (waterAnimTick / 48) % 2
        let baseTexture = renderLayer(includeTreeTops: false, waterFrame: frame)
        let topTexture = renderLayer(includeTreeTops: true, waterFrame: frame)

        let base = SKSpriteNode(texture: baseTexture)
        base.anchorPoint = CGPoint(x: 0, y: 0)
        base.position = .zero
        base.size = worldSize
        base.zPosition = 0
        base.texture?.filteringMode = .nearest
        worldNode.addChild(base)

        let top = SKSpriteNode(texture: topTexture)
        top.anchorPoint = CGPoint(x: 0, y: 0)
        top.position = .zero
        top.size = worldSize
        top.zPosition = 40
        top.texture?.filteringMode = .nearest
        topOverlayNode.addChild(top)
    }

    private func renderLayer(includeTreeTops: Bool, waterFrame: Int) -> SKTexture {
        let widthPx = levelWidth * 16
        let heightPx = levelHeight * 16
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let ctx = CGContext(
            data: nil,
            width: widthPx,
            height: heightPx,
            bitsPerComponent: 8,
            bytesPerRow: widthPx * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return SKTexture()
        }

        ctx.interpolationQuality = .none
        ctx.setShouldAntialias(false)

        if !includeTreeTops {
            // В оригинальном Genesis это два отдельных прохода:
            // 1) весь базовый слой (земля)
            // 2) postRender (стволы деревьев, факелы)
            // Если рисовать стволы в том же проходе, следующие тайлы земли их затирают.
            for y in 0..<levelHeight {
                for x in 0..<levelWidth {
                    let ground = groundTileAt(x: x, y: y)
                    let groundSprite = groundTileSprite(ground, waterFrame: waterFrame)
                    drawSprite(ctx, tileX: groundSprite.0, tileY: groundSprite.1, atX: x, atY: y)
                }
            }

            for y in 0..<levelHeight {
                for x in 0..<levelWidth {
                    switch overlayTileAt(x: x, y: y) {
                    case .tree:
                        drawSprite(ctx, tileX: 5, tileY: 1, atX: x, atY: y + 1)
                        drawSprite(ctx, tileX: 6, tileY: 1, atX: x + 1, atY: y + 1)
                    case .snowTree:
                        drawSprite(ctx, tileX: 7, tileY: 1, atX: x, atY: y + 1)
                        drawSprite(ctx, tileX: 8, tileY: 1, atX: x + 1, atY: y + 1)
                    case .torch:
                        drawSprite(ctx, tileX: 0, tileY: 1, atX: x, atY: y)
                    case .none:
                        break
                    }
                }
            }
        } else {
            for y in 0..<levelHeight {
                for x in 0..<levelWidth {
                    switch overlayTileAt(x: x, y: y) {
                    case .tree:
                        drawSprite(ctx, tileX: 5, tileY: 0, atX: x, atY: y)
                        drawSprite(ctx, tileX: 6, tileY: 0, atX: x + 1, atY: y)
                    case .snowTree:
                        drawSprite(ctx, tileX: 7, tileY: 0, atX: x, atY: y)
                        drawSprite(ctx, tileX: 8, tileY: 0, atX: x + 1, atY: y)
                    default:
                        break
                    }
                }
            }
        }

        guard let cg = ctx.makeImage() else { return SKTexture() }
        let texture = SKTexture(cgImage: cg)
        texture.filteringMode = .nearest
        return texture
    }

    private func groundTileSprite(_ tile: GroundTile, waterFrame: Int) -> (Int, Int) {
        switch tile {
        case .grassGround: return (0, 0)
        case .grass: return (2, 0)
        case .rock: return (4, 0)
        case .water: return (waterFrame == 0 ? 1 : 2, 1)
        case .snow: return (3, 1)
        case .ice: return (4, 1)
        case .flower: return (3, 0)
        case .snowRock: return (3, 2)
        case .voidTile: return (0, 0)
        }
    }

    private func textureForGround(_ tile: GroundTile, waterFrame: Int) -> SKTexture {
        switch tile {
        case .grassGround: return spriteTexture(tileX: 0, tileY: 0)
        case .grass: return spriteTexture(tileX: 2, tileY: 0)
        case .rock: return spriteTexture(tileX: 4, tileY: 0)
        case .water: return spriteTexture(tileX: waterFrame == 0 ? 1 : 2, tileY: 1)
        case .snow: return spriteTexture(tileX: 3, tileY: 1)
        case .ice: return spriteTexture(tileX: 4, tileY: 1)
        case .flower: return spriteTexture(tileX: 3, tileY: 0)
        case .snowRock: return spriteTexture(tileX: 3, tileY: 2)
        case .voidTile: return spriteTexture(tileX: 0, tileY: 0)
        }
    }

    private func mobTexture(kind: Mob.Kind, dir: Int, walking: Bool, anim: Int, femaleCanSpawnChild: Bool = true) -> SKTexture {
        switch kind {
        case .player:
            // Герой: тёмный олень с рогами (набор из строки y=7).
            // Меняем верх/низ местами: при движении "вниз к камере" должен быть фронт.
            if dir == 0 { return walking ? spriteTexture(tileX: 3, tileY: 7) : spriteTexture(tileX: 2, tileY: 7) }
            if dir == 1 { return walking && anim % 250 <= 125 ? spriteTexture(tileX: 5, tileY: 7) : spriteTexture(tileX: 4, tileY: 7) }
            if dir == 2 { return walking ? spriteTexture(tileX: 1, tileY: 7) : spriteTexture(tileX: 0, tileY: 7) }
            return walking && anim % 250 <= 125 ? spriteTexture(tileX: 5, tileY: 7) : spriteTexture(tileX: 4, tileY: 7)

        case .forestMob, .oceanMob:
            // Новорождённые: более светлый олень с рогами (набор из строки y=9).
            if dir == 0 { return walking ? spriteTexture(tileX: 3, tileY: 9) : spriteTexture(tileX: 2, tileY: 9) }
            if dir == 1 { return walking && anim % 250 <= 125 ? spriteTexture(tileX: 5, tileY: 9) : spriteTexture(tileX: 4, tileY: 9) }
            if dir == 2 { return walking ? spriteTexture(tileX: 1, tileY: 9) : spriteTexture(tileX: 0, tileY: 9) }
            return walking && anim % 250 <= 125 ? spriteTexture(tileX: 5, tileY: 9) : spriteTexture(tileX: 4, tileY: 9)

        case .female:
            // Самки:
            // - canSpawnChild = true  -> чёрный нос/хвост (не оплодотворена), строка y=7
            // - canSpawnChild = false -> красный нос/хвост (оплодотворена), строка y=9
            let row = femaleCanSpawnChild ? 7 : 9
            if dir == 0 { return walking ? spriteTexture(tileX: 9, tileY: row) : spriteTexture(tileX: 8, tileY: row) }
            if dir == 1 { return walking && anim % 250 <= 125 ? spriteTexture(tileX: 11, tileY: row) : spriteTexture(tileX: 10, tileY: row) }
            if dir == 2 { return walking ? spriteTexture(tileX: 7, tileY: row) : spriteTexture(tileX: 6, tileY: row) }
            return walking && anim % 250 <= 125 ? spriteTexture(tileX: 11, tileY: row) : spriteTexture(tileX: 10, tileY: row)

        case .predator:
            if dir == 0 { return spriteTexture(tileX: 2, tileY: 8) }
            if dir == 1 { return spriteTexture(tileX: 0, tileY: 8) }
            if dir == 2 { return spriteTexture(tileX: 1, tileY: 8) }
            return spriteTexture(tileX: 0, tileY: 8)
        }
    }

    private func syncMobNode(_ mob: Mob) {
        // У нас anchorPoint = (0, 0). При xScale = -1 спрайт зеркалится относительно левого края
        // и визуально «уезжает» на 16px влево. Компенсируем это сдвигом на ширину тайла.
        let flipOffsetX: CGFloat = (mob.dir == 3) ? 16 : 0
        mob.node.position = CGPoint(x: mob.x + flipOffsetX, y: mob.y)
        mob.node.texture = mobTexture(
            kind: mob.kind,
            dir: mob.dir,
            walking: mob.walking,
            anim: mob.anim,
            femaleCanSpawnChild: mob.canSpawnChild
        )
        mob.node.xScale = (mob.dir == 3) ? -1 : 1
    }

    private func spawnFemalePoint() -> SpawnPoint {
        // Спавним по всей карте, но не в текущей зоне видимости игрока.
        for _ in 0..<400 {
            let worldTileX = Int.random(in: 0..<levelWidth)
            let worldTileY = Int.random(in: 0..<levelHeight)
            let mapTileY = levelHeight - 1 - worldTileY

            if solid(tileAt: worldTileX, y: mapTileY) { continue }
            if solidOverlay(tileAt: worldTileX, y: mapTileY) { continue }

            let spawnX = CGFloat(worldTileX * 16)
            let spawnY = CGFloat(worldTileY * 16)
            if isInPlayerVisibleArea(x: spawnX + 8, y: spawnY + 8) { continue }

            return .init(x: spawnX, y: spawnY)
        }

        // Fallback: если подходящая точка не нашлась, возвращаем старую универсальную.
        return .init(x: CGFloat(Int.random(in: 0..<(levelWidth * 16))), y: CGFloat(Int.random(in: 0..<(levelHeight * 16))))
    }

    private func isInPlayerVisibleArea(x: CGFloat, y: CGFloat) -> Bool {
        guard player != nil else { return false }

        let halfVisibleWidth = (size.width * cameraNode2D.xScale) * 0.5
        let halfVisibleHeight = (size.height * cameraNode2D.yScale) * 0.5
        let extraMargin: CGFloat = 32

        let visibleRect = CGRect(
            x: cameraNode2D.position.x - halfVisibleWidth - extraMargin,
            y: cameraNode2D.position.y - halfVisibleHeight - extraMargin,
            width: (halfVisibleWidth + extraMargin) * 2,
            height: (halfVisibleHeight + extraMargin) * 2
        )

        return visibleRect.contains(CGPoint(x: x, y: y))
    }

    private func spawnGenericMobPoint() -> SpawnPoint {
        switch selectedBiome {
        case .forest:
            return .init(x: CGFloat(Int.random(in: 16...(127 * 16 + 16))), y: CGFloat(101 * 16))
        case .ocean:
            return .init(x: CGFloat(Int.random(in: (54 * 16)...(74 * 16))), y: CGFloat(23 * 16))
        case .snow:
            return .init(x: CGFloat(Int.random(in: (62 * 16)...(105 * 16))), y: CGFloat(Int.random(in: (95 * 16)...(112 * 16))))
        }
    }

    private func loadSheetIfNeeded() {
        if spriteSheet != nil { return }
        if let img = UIImage(named: "genesis_sprites_1")?.cgImage {
            spriteSheet = makeMagentaTransparent(image: img)
        }
    }

    private func makeMagentaTransparent(image: CGImage) -> CGImage {
        let width = image.width
        let height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return image
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        for i in stride(from: 0, to: bytes.count, by: 4) {
            let r = bytes[i]
            let g = bytes[i + 1]
            let b = bytes[i + 2]
            let brightMagenta = r >= 235 && b >= 235 && g <= 30
            let darkMagenta = r >= 100 && b >= 100 && g <= 30 && abs(Int(r) - Int(b)) <= 25
            if brightMagenta || darkMagenta {
                bytes[i] = 0
                bytes[i + 1] = 0
                bytes[i + 2] = 0
                bytes[i + 3] = 0
            }
        }

        return context.makeImage() ?? image
    }

    private func spriteCGImage(tileX: Int, tileY: Int) -> CGImage? {
        let key = "\(tileX)_\(tileY)"
        if let cached = tileImageCache[key] { return cached }
        guard let sheet = spriteSheet else { return nil }
        let rect = CGRect(x: tileX * 16, y: tileY * 16, width: 16, height: 16)
        guard let cg = sheet.cropping(to: rect) else { return nil }
        tileImageCache[key] = cg
        return cg
    }

    private func spriteTexture(tileX: Int, tileY: Int) -> SKTexture {
        let key = "\(tileX)_\(tileY)"
        if let cached = textureCache[key] { return cached }
        guard let cg = spriteCGImage(tileX: tileX, tileY: tileY) else { return SKTexture() }
        let texture = SKTexture(cgImage: cg)
        texture.filteringMode = .nearest
        textureCache[key] = texture
        return texture
    }

    private func drawSprite(_ ctx: CGContext, tileX: Int, tileY: Int, atX: Int, atY: Int) {
        guard let cg = spriteCGImage(tileX: tileX, tileY: tileY) else { return }
        let drawY = (levelHeight - atY - 1) * 16
        ctx.draw(cg, in: CGRect(x: atX * 16, y: drawY, width: 16, height: 16))
    }

    private func pixelsFromImage(_ image: CGImage) -> (Int, Int, [UInt32]) {
        let width = image.width
        let height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let bytesPerRow = width * 4

        guard let context = CGContext(
            data: &bytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            return (width, height, [])
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var result = [UInt32](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            let r = UInt32(bytes[i * 4])
            let g = UInt32(bytes[i * 4 + 1])
            let b = UInt32(bytes[i * 4 + 2])
            let a = UInt32(bytes[i * 4 + 3])
            result[i] = (a << 24) | (r << 16) | (g << 8) | b
        }
        return (width, height, result)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let pointInCamera = touch.location(in: cameraNode2D)

        switch state {
        case .menu:
            if let nearest = biomeLabels.min(by: {
                abs($0.value.position.y - pointInCamera.y) < abs($1.value.position.y - pointInCamera.y)
            }), abs(nearest.value.position.y - pointInCamera.y) < 34 {
                startGame(with: nearest.key)
                return
            }

            if let tappedName = cameraNode2D
                .nodes(at: pointInCamera)
                .compactMap(\ .name)
                .first(where: { $0.hasPrefix("biome_") }),
               let biome = Biome.allCases.first(where: { "biome_\($0.title)" == tappedName }) {
                startGame(with: biome)
                return
            }

            for (biome, label) in biomeLabels where label.contains(pointInCamera) {
                startGame(with: biome)
                return
            }
        case .gameOver:
            return
        case .paused:
            return
        case .playing:
            return
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        return
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        return
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}
