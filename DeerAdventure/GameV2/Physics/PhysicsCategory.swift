import Foundation

struct PhysicsCategory {
    static let none:    UInt32 = 0
    static let player:  UInt32 = 0b00001
    static let female:  UInt32 = 0b00010
    static let mob:     UInt32 = 0b00100
    static let terrain: UInt32 = 0b01000
    static let world:   UInt32 = 0b10000
}
