public enum CalibrationReadiness: UInt8 {
    case Ready = 0
    case NotEnoughData = 1
    case GlucoseTooHigh = 2
    case TooSoon = 3
    case DropoutPhase = 4
    case SensorEol = 5
    case NoSensorLinked = 6
    case UnsupportedMode = 7
    case Calibrating = 8
    case LedDisconnectDetected = 9
    case TransmitterEol = 10
    case Unknown = 255

    var description: String {
        switch self {
        case .Ready:
            return String(localized: "Ready for calibration", comment: "title for Ready")
        case .NotEnoughData:
            return String(localized: "Not enough data", comment: "title for NotEnoughData")
        case .GlucoseTooHigh:
            return String(localized: "Glucose is too high", comment: "title for GlucoseTooHigh")
        case .TooSoon:
            return String(localized: "Too soon", comment: "title for TooSoon")
        case .DropoutPhase:
            return String(localized: "Dropout phase", comment: "title for DropoutPhase")
        case .SensorEol:
            return String(localized: "Sensor is expired", comment: "title for SensorEol")
        case .NoSensorLinked:
            return String(localized: "No sensor linked", comment: "title for NoSensorLinked")
        case .UnsupportedMode:
            return String(localized: "Unsupported", comment: "title for UnsupportedMode")
        case .Calibrating:
            return String(localized: "Calibration in progress", comment: "title for Calibrating")
        case .LedDisconnectDetected:
            return String(localized: "Disconnect detected", comment: "title for LedDisconnectDetected")
        case .TransmitterEol:
            return String(localized: "Transmitter is expired", comment: "title for TransmitterEol")
        case .Unknown:
            return String(localized: "Unknown", comment: "title for Unknown")
        }
    }
}
