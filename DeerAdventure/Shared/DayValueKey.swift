import Foundation

enum DayValueKey {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func make(from date: Date) -> String {
        formatter.string(from: Calendar.current.startOfDay(for: date))
    }

    static func parse(_ key: String) -> Date? {
        formatter.date(from: key)
    }
}
