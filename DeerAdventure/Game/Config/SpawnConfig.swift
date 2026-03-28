import CoreGraphics

enum SpawnConfig {
    struct BiomeSpawn {
        let player: CGPoint
        let female: CGPoint
    }

    static let forest = BiomeSpawn(
        player: CGPoint(x: 9 * 16, y: 100 * 16),
        female: CGPoint(x: 21 * 16, y: 102 * 16)
    )

    static let snow = BiomeSpawn(
        player: CGPoint(x: 80 * 16, y: 100 * 16),
        female: CGPoint(x: 105 * 16, y: 94 * 16)
    )

    static let ocean = BiomeSpawn(
        player: CGPoint(x: 54 * 16, y: 23 * 16),
        female: CGPoint(x: 66 * 16, y: 26 * 16)
    )
}
