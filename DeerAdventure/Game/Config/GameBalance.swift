import Foundation

enum GameBalance {
    /// Total game duration in seconds (5 minutes).
    static let gameDuration = 5 * 60

    /// Base range of offspring spawned per breeding event (before multiplier).
    static let breedingBaseCount: ClosedRange<Int> = 1...4

    /// Maximum allowed breeding multiplier value.
    static let maxBreedingMultiplier = 100
}
