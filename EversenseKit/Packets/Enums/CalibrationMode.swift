public enum CalibrationMode: UInt8 {
    case DailySingle = 1
    case DailyDual = 2
    case WeeklySingle = 3
    case Default = 4

    static func from365(rawValue: UInt8) -> CalibrationMode {
        switch rawValue {
        case 0: return .DailySingle
        case 1: return .WeeklySingle
        default: return .Default
        }
    }

    func toPeriod() -> TimeInterval {
        switch self {
        case .DailySingle: return .hours(24)
        case .DailyDual: return .hours(12)
        case .WeeklySingle: return .days(7)
        case .Default: return .hours(24) // Is this correct???
        }
    }
}
