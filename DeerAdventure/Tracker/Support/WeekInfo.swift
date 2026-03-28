import Foundation

struct WeekInfo: Identifiable {
    let id: Int
    let weekOfYear: Int
    let title: String
    let range: String
    let trailingValue: String
    let monthName: String
    let year: Int
    let startDate: Date
    let endDate: Date
}
