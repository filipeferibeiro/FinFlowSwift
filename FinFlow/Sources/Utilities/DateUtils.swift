import Foundation

public enum DateUtils {
    private static let monthKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()

    private static let dayHeaderFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd 'de' MMMM"
        return formatter
    }()

    private static let currentYearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    private static let otherYearMonthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMM y"
        return formatter
    }()

    /// Stable month key in `yyyy-MM` format for persistence and recurring overrides.
    public static func monthKey(for date: Date) -> String {
        monthKeyFormatter.string(from: date)
    }

    /// Formats a date as a localized section header (e.g. "17 de outubro").
    public static func formattedDay(_ date: Date) -> String {
        dayHeaderFormatter.string(from: date)
    }

    /// Formats a month name, omitting the year if it matches the current year.
    public static func monthName(for date: Date, referenceDate: Date = .now) -> String {
        let calendar = Calendar.current
        let isCurrentYear = calendar.component(.year, from: date) == calendar.component(.year, from: referenceDate)
        if isCurrentYear {
            return currentYearMonthFormatter.string(from: date).capitalized
        } else {
            return otherYearMonthFormatter.string(from: date).capitalized
        }
    }

    /// Localized time-of-day greeting.
    public static func greeting(for date: Date = .now) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        return switch hour {
        case 6..<12: "Bom dia"
        case 12..<18: "Boa tarde"
        case 18..<24, 0..<6: "Boa noite"
        default: "Olá"
        }
    }

    /// Returns the first and last instant/day of the month containing `date`.
    public static func monthBounds(for date: Date, calendar: Calendar = .current) -> (start: Date, end: Date)? {
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return nil
        }
        return (startOfMonth, endOfMonth)
    }

    /// Projects a template's day-of-month into `targetMonthDate`, clamping days 29–31 to the last valid day of the month.
    public static func clampedRecurringDate(from templateDate: Date, inMonthOf targetMonthDate: Date, calendar: Calendar = .current) -> Date? {
        guard let (startOfMonth, _) = monthBounds(for: targetMonthDate, calendar: calendar),
              let dayRange = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return nil
        }

        let sourceComponents = calendar.dateComponents([.day, .hour, .minute, .second], from: templateDate)
        var targetComponents = calendar.dateComponents([.year, .month], from: startOfMonth)

        let desiredDay = sourceComponents.day ?? 1
        targetComponents.day = min(max(desiredDay, dayRange.lowerBound), dayRange.upperBound - 1)
        targetComponents.hour = sourceComponents.hour
        targetComponents.minute = sourceComponents.minute
        targetComponents.second = sourceComponents.second

        return calendar.date(from: targetComponents)
    }

    /// Returns a `Date` in `targetMonthDate` corresponding to `dayOfMonth` (1...31), clamped to the valid days of that month.
    public static func date(forDay dayOfMonth: Int, inMonthOf targetMonthDate: Date, calendar: Calendar = .current) -> Date? {
        guard let (startOfMonth, _) = monthBounds(for: targetMonthDate, calendar: calendar),
              let dayRange = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return nil
        }

        var targetComponents = calendar.dateComponents([.year, .month], from: startOfMonth)
        targetComponents.day = min(max(dayOfMonth, dayRange.lowerBound), dayRange.upperBound - 1)
        targetComponents.hour = 12
        targetComponents.minute = 0
        targetComponents.second = 0

        return calendar.date(from: targetComponents)
    }

    /// Generates a deterministic UUID from a template UUID and month key (`yyyy-MM`) so virtual transactions keep stable identity.
    public static func deterministicUUID(from baseUUID: UUID, monthKey: String) -> UUID {
        var bytes = withUnsafeBytes(of: baseUUID.uuid) { Array($0) }
        let monthBytes = Array(monthKey.utf8)
        for (index, byte) in monthBytes.enumerated() {
            bytes[index % 16] ^= byte &+ UInt8(truncatingIfNeeded: index &* 31)
        }
        // Set UUID version 5 (name-based) & RFC 4122 variant bits
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        let uuidTuple: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: uuidTuple)
    }
}
