enum CalibrationFlag: UInt8 {
    case NOT_ENTERED_FOR_CALIBRATION = 0
    case ACTUALLY_USED_FOR_CALIBRATION = 1
    case MARKED_SUSPICIOUS = 2
    case GLUCOSE_TOO_LOW_TO_READ = 3
    case GLUCOSE_TOO_HIGH_TO_READ = 4
    case GLUCOSE_RAPID_CHANGE = 5
    case INVALID_TIME = 6
    case INSUFFICIENT_DATA = 7
    case SENSOR_EOL = 8
    case DROPOUT_PHASE = 9
    case AUTO_LINK_MODE_ACTIVE = 10
    case SENSOR_LED_DISCONNECT = 11
    case OTHER_FAILURE = 12
    case THIS_ONE_USED_PREVIOUS_ONE_DELETED = 13
    case THIS_SUSPICIOUS_PREVIOUS_DELETED = 14
    case INSUFFICIENT_DATA_POST_FS_ENTRY = 15
    case UNKNOWN_FAILURE = 255

    func getTitle() -> String {
        switch self {
        case .ACTUALLY_USED_FOR_CALIBRATION,
             .NOT_ENTERED_FOR_CALIBRATION:
            return String(localized: "Calibration accepted", comment: "calibration flag - accepted")
        case .MARKED_SUSPICIOUS:
            return String(localized: "Suspicious", comment: "calibration flag - suspicious")
        case .GLUCOSE_TOO_LOW_TO_READ:
            return String(localized: "Glucose too low", comment: "calibration flag - too low")
        case .GLUCOSE_TOO_HIGH_TO_READ:
            return String(localized: "Glucose too high", comment: "calibration flag - too high")
        case .GLUCOSE_RAPID_CHANGE:
            return String(localized: "Glucose changing too fast", comment: "calibration flag - rapid change")
        case .INVALID_TIME:
            return String(localized: "Invalid time", comment: "calibration flag - invalid time")
        case .INSUFFICIENT_DATA,
             .INSUFFICIENT_DATA_POST_FS_ENTRY:
            return String(localized: "Insufficient data", comment: "calibration flag - insuficient data")
        case .SENSOR_EOL:
            return String(localized: "Sensor End of Life", comment: "calibration flag - Sensor EOL")
        case .DROPOUT_PHASE:
            return String(localized: "Dropout phase", comment: "calibration flag - dropout phase")
        case .AUTO_LINK_MODE_ACTIVE:
            return String(localized: "Autolink", comment: "calibration flag - autolink mode")
        case .SENSOR_LED_DISCONNECT:
            return String(localized: "Sensor disconnected", comment: "calibration flag - sensor led disconnected")
        case .OTHER_FAILURE:
            return String(localized: "Other failure", comment: "calibration flag - other failure")
        case .THIS_ONE_USED_PREVIOUS_ONE_DELETED,
             .THIS_SUSPICIOUS_PREVIOUS_DELETED:
            return String(localized: "Previous calibration deleted", comment: "calibration flag - this one used")
        case .UNKNOWN_FAILURE:
            return String(localized: "Unknown failure", comment: "calibration flag - unknown")
        }
    }
}
