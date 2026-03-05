import Foundation

extension Date {

    /// Formatierung für die Konversationsliste (relativ für aktuelle Woche, sonst Datum)
    var conversationListTimestamp: String {
        let cal = Calendar.current
        if cal.isDateInToday(self) {
            return formatted(date: .omitted, time: .shortened)
        } else if cal.isDateInYesterday(self) {
            return "Gestern"
        } else if cal.isDate(self, equalTo: .now, toGranularity: .weekOfYear) {
            return formatted(.dateTime.weekday(.abbreviated))
        } else {
            return formatted(.dateTime.day().month())
        }
    }

    /// Vollständiger Zeitstempel für Mail-Header
    var fullTimestamp: String {
        formatted(date: .long, time: .standard)
    }
}
