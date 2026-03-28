import SwiftData

@Model
final class DayValueEntry {
    @Attribute(.unique) var dateKey: String
    var value: Int

    init(dateKey: String, value: Int) {
        self.dateKey = dateKey
        self.value = value
    }
}
