enum AlarmType {
    case Critical
    case Warning
    case Info
}

public enum Alarm: UInt8, Codable {
    case CriticalFaultAlarm = 0
    case SensorRetiredAlarm = 1
    case EmptyBatteryAlarm = 2
    case SensorTemperatureAlarm = 3
    case SensorLowTemperatureAlarm = 4
    case ReaderTemperatureAlarm = 5
    case SensorAwolAlarm = 6
    case InvalidSensorAlarm = 7
    case CalibrationRequiredAlarm = 8
    case SeriouslyLowAlarm = 9
    case SeriouslyHighAlarm = 10
    case LowGlucoseAlarm = 11
    case HighGlucoseAlarm = 12
    case PredictiveLowAlarm = 13
    case PredictiveHighAlarm = 14
    case RateFallingAlarm = 15
    case RateRisingAlarm = 16
    case CalibrationGracePeriodAlarm = 17
    case CalibrationExpiredAlarm = 18
    case SensorRetiringSoon1Alarm = 19
    case SensorRetiringSoon3Alarm = 20
    case SensorRetiringSoon4Alarm = 21
    case SensorRetiringSoon5Alarm = 22
    case SensorRetiringSoon6Alarm = 23
    case SensorRetiringSoon7Alarm = 36
    case VeryLowBatteryAlarm = 24
    case InvalidClockAlarm = 25
    case TransmitterDisconnected = 27
    case VibrationCurrentAlarm = 28
    case MSPAlarm = 29
    case CalibrationFailedAlert = 30
    case CalibrationSuspiciousAlert = 31
    case CalibrationNowAlarm = 32
    case TransmitterEOL396 = 33
    case TransmitterEOL366 = 34
    case BatteryErrorAlarm = 35
    case TransmitterEOL330 = 37
    case TransmitterEOL395 = 38
    case OneCal = 39
    case CalibrationSuspicious2Alert = 40
    case BatteryStatusAlarm = 41
    case SensorConnection = 42
    case EarlySensorRetirement = 43
    case GeneralGlucoseSuspended = 44
    case SensorGraceAlarm = 45
    case SensorSyncConfirmedAlarm = 46
    case TxDockedAlert = 47
    case TxUndockedAlert = 48
    case TransmitterReconnected = 49
    case TransmitterKeepAliveNotReceived = 50
    case TransmitterGlucoseStale = 51
    case SystemTime = 52
    case IncompatibleTx = 53
    case SensorFile = 54
    case SensorRelink = 55
//    case NewPasswordDetected = 56
    case BatteryOptimization = 57
    case WarmUpPhaseCompleteAlert = 58
    case ResetLogReport = 59
    case InValidTx = 60
//    case RomeSensorLinkFail = 61
//    case RomeSensorUnlinkable = 62
    case TxPairingError = 63
    case TxPairingErrorOnKeyInvalid = 64
    case TransmitterOrSensorConnectionLostDuringLinking = 65
    case PairingMetricsError = 66
    case SmfSyncFailed = 67
    case OtaUpgradeComplete = 69
    case NoAlarmActive = 74
    case TwoCal = 90
    case unknown = 255

    static let warningAlarms: [Alarm] = [.CalibrationNowAlarm, .CalibrationFailedAlert]
    static let criticalAlarms: [Alarm] = [
        .CalibrationRequiredAlarm,
        .CalibrationExpiredAlarm,
        .BatteryErrorAlarm,
        .ReaderTemperatureAlarm,
        .SensorTemperatureAlarm,
        .SensorLowTemperatureAlarm
    ]

    var type: AlarmType {
        switch self {
        case .BatteryOptimization,
             .BatteryStatusAlarm,
             .InValidTx,
             .OneCal,
             .OtaUpgradeComplete,
             .ResetLogReport,
             .SensorRetiringSoon1Alarm,
             .SensorRetiringSoon3Alarm,
             .SensorRetiringSoon4Alarm,
             .SensorRetiringSoon5Alarm,
             .SensorRetiringSoon6Alarm,
             .SensorRetiringSoon7Alarm,
             .SensorSyncConfirmedAlarm,
             .TwoCal,
             .WarmUpPhaseCompleteAlert:
            return .Info

        case .CalibrationFailedAlert,
             .CalibrationSuspicious2Alert,
             .CalibrationSuspiciousAlert,
             .InvalidClockAlarm,
             .InvalidSensorAlarm,
             .PredictiveHighAlarm,
             .PredictiveLowAlarm,
             .RateFallingAlarm,
             .RateRisingAlarm,
             .TransmitterEOL330,
             .TransmitterEOL366,
             .TransmitterEOL395:
            return .Warning

        default:
            return .Critical
        }
    }

    var title: String {
        switch self {
        case .CriticalFaultAlarm:
            return LocalizedString("Transmitter Error", comment: "title for CriticalFaultAlarm")
        case .SensorGraceAlarm,
             .SensorRetiredAlarm,
             .SensorRetiringSoon1Alarm,
             .SensorRetiringSoon3Alarm,
             .SensorRetiringSoon4Alarm,
             .SensorRetiringSoon5Alarm,
             .SensorRetiringSoon6Alarm,
             .SensorRetiringSoon7Alarm:
            return LocalizedString("Sensor Replacement", comment: "title for SensorRetiredAlarm")
        case .EmptyBatteryAlarm:
            return LocalizedString("Battery Empty", comment: "title for EmptyBatteryAlarm")
        case .SensorTemperatureAlarm:
            return LocalizedString("High Sensor Temperature", comment: "title for SensorTemperatureAlarm")
        case .SensorLowTemperatureAlarm:
            return LocalizedString("Low Sensor Temperature", comment: "title for SensorLowTemperatureAlarm")
        case .ReaderTemperatureAlarm:
            return LocalizedString("High Transmitter Temperature", comment: "title for ReaderTemperatureAlarm")
        case .SensorAwolAlarm:
            return LocalizedString("No Sensor Detected", comment: "title for SensorAwolAlarm")
        case .InvalidSensorAlarm:
            return LocalizedString("New Sensor Detected", comment: "title for InvalidSensorAlarm")
        case .CalibrationRequiredAlarm:
            return LocalizedString("Calibrate Now", comment: "title for CalibrationRequiredAlarm")
        case .SeriouslyLowAlarm:
            return LocalizedString("Out of Range Low Glucose", comment: "title for SeriouslyLowAlarm")
        case .SeriouslyHighAlarm:
            return LocalizedString("Out of Range High Glucose", comment: "title for SeriouslyHighAlarm")
        case .LowGlucoseAlarm:
            return LocalizedString("Low Glucose", comment: "title for LowGlucoseAlarm")
        case .HighGlucoseAlarm:
            return LocalizedString("High Glucose", comment: "title for HighGlucoseAlarm")
        case .PredictiveLowAlarm:
            return LocalizedString("Predicted Low Glucose", comment: "title for PredictiveLowAlarm")
        case .PredictiveHighAlarm:
            return LocalizedString("Predicted High Glucose", comment: "title for PredictiveHighAlarm")
        case .RateFallingAlarm:
            return LocalizedString("Rate Falling", comment: "title for RateFallingAlarm")
        case .RateRisingAlarm:
            return LocalizedString("Rate Rising", comment: "title for RateRisingAlarm")
        case .CalibrationGracePeriodAlarm:
            return LocalizedString("Calibration Past Due", comment: "title for CalibrationGracePeriodAlarm")
        case .CalibrationExpiredAlarm:
            return LocalizedString("Calibration Expired", comment: "title for CalibrationExpiredAlarm")
        case .VeryLowBatteryAlarm:
            return LocalizedString("Low Battery", comment: "title for VeryLowBatteryAlarm")
        case .InvalidClockAlarm:
            return LocalizedString("Invalid Transmitter Time", comment: "title for InvalidClockAlarm")
        case .TransmitterDisconnected:
            return LocalizedString("Transmitter Disconnected", comment: "title for TransmitterDisconnected")
        case .VibrationCurrentAlarm:
            return LocalizedString("Vibration Motor", comment: "title for VibrationCurrentAlarm")
        case .MSPAlarm:
            return LocalizedString("Sensor Replacement", comment: "title for MSPAlarm")
        case .CalibrationFailedAlert:
            return LocalizedString("Calibrate Again", comment: "title for CalibrationFailedAlert")
        case .CalibrationSuspiciousAlert:
            return LocalizedString("New Calibration Needed", comment: "title for CalibrationSuspiciousAlert")
        case .CalibrationNowAlarm,
             .CalibrationSuspicious2Alert:
            return LocalizedString("Calibrate Now", comment: "title for CalibrationNowAlarm")
        case .TransmitterEOL330,
             .TransmitterEOL366,
             .TransmitterEOL395,
             .TransmitterEOL396:
            return LocalizedString("Transmitter Replacement", comment: "title for TransmitterEOL")
        case .BatteryErrorAlarm:
            return LocalizedString("Battery Error", comment: "title for BatteryErrorAlarm")
        case .OneCal:
            return LocalizedString("1 Weekly Calibration Phase", comment: "title for OneCal")
        case .TwoCal:
            return LocalizedString("2 daily Calibration Phase", comment: "title for OneCal")
        case .BatteryStatusAlarm:
            return LocalizedString("Battery Status", comment: "title for BatteryStatusAlarm")
        case .SensorConnection:
            return LocalizedString("Sensor Connection", comment: "title for SensorConnection")
        case .EarlySensorRetirement:
            return LocalizedString("Sensor Retirement Area", comment: "title for EarlySensorRetirement")
        case .GeneralGlucoseSuspended:
            return LocalizedString("Glucose Suspend", comment: "title for GeneralGlucoseSuspended")
        case .SensorSyncConfirmedAlarm:
            return LocalizedString("Sensor Sync Confirmed", comment: "title for SensorSyncConfirmedAlarm")
        case .TxDockedAlert:
            return LocalizedString("Transmitter Inactive", comment: "title for TxDockedAlert")
        case .TxUndockedAlert:
            return LocalizedString("Transmitter Active", comment: "title for TxUndockedAlert")
        case .TransmitterReconnected:
            return LocalizedString("Transmitter Connected", comment: "title for TransmitterReconnected")
        case .TransmitterGlucoseStale,
             .TransmitterKeepAliveNotReceived:
            return LocalizedString("Data Unavailable", comment: "title for TransmitterKeepAliveNotReceived")
        case .SystemTime:
            return LocalizedString("System Time", comment: "title for SystemTime")
        case .IncompatibleTx,
             .InValidTx:
            return LocalizedString("Incompatible Transmitter", comment: "title for IncompatibleTx")
        case .SensorFile:
            return LocalizedString("Sensor File", comment: "title for SensorFile")
        case .SensorRelink:
            return LocalizedString("Sensor Re-link", comment: "title for SensorRelink")
        case .BatteryOptimization:
            return LocalizedString("Battery optimization", comment: "title for BatteryOptimization")
        case .WarmUpPhaseCompleteAlert:
            return LocalizedString("Warm-Up Complete", comment: "title for WarmUpPhaseCompleteAlert")
        case .ResetLogReport:
            return LocalizedString("Transmitter Reset", comment: "title for ResetLogReport")
        case .TxPairingError,
             .TxPairingErrorOnKeyInvalid:
            return LocalizedString("Pairing Error", comment: "title for TxPairingError")
        case .TransmitterOrSensorConnectionLostDuringLinking:
            return LocalizedString("Connection Lost", comment: "title for TransmitterOrSensorConnectionLostDuringLinking")
        case .PairingMetricsError:
            return LocalizedString("Pairing Metrics", comment: "title for PairingMetricsError")
        case .SmfSyncFailed:
            return LocalizedString("SMF Sync Failed", comment: "title for SmfSyncFailed")
        case .NoAlarmActive:
            return LocalizedString("", comment: "title for NoAlarmActive")
        case .OtaUpgradeComplete:
            return LocalizedString("", comment: "title for NoAlarmActive")
        case .unknown:
            return LocalizedString("Unknown error", comment: "title for unknown")
        }
    }

    var description: String? {
        switch self {
        case .CriticalFaultAlarm:
            return LocalizedString(
                "Your transmitter has detected an error. Please contact Eversense Customer Support.",
                comment: "description for CriticalFaultAlarm"
            )
        case .EmptyBatteryAlarm:
            return LocalizedString(
                "Your transmitter's battery is empty. Please recharge transmitter now to resume sensor glucose display.",
                comment: "description for EmptyBatteryAlarm"
            )
        case .SensorTemperatureAlarm:
            return LocalizedString(
                "Your sensor's temperature is too high. Please go to a cooler place to resume receiving sensor glucose values. If the problem persists, contact Eversense Customer Support.",
                comment: "description for SensorTemperatureAlarm"
            )
        case .SensorLowTemperatureAlarm:
            return LocalizedString(
                "Your sensor's temperature is too low. Please go to a warmer place to resume receiving sensor glucose readings. If the problem persists, contact Eversense Customer Support.",
                comment: "description for SensorLowTemperatureAlarm"
            )
        case .ReaderTemperatureAlarm:
            return LocalizedString(
                "Your transmitter's temperature is too high. Go to a cooler area to resume receiving sensor glucose readings. If the problem persists, contact Eversense Customer Support.",
                comment: "description for ReaderTemperatureAlarm"
            )
        case .SensorAwolAlarm:
            return LocalizedString(
                "The connection between your sensor and transmitter is lost. No glucose data is available until the connection is restored.",
                comment: "description for SensorAwolAlarm"
            )
        case .InvalidSensorAlarm:
            return LocalizedString(
                "A new sensor has been detected. If you have a new sensor and/or transmitter, please link your sensor and transmitter.",
                comment: "description for InvalidSensorAlarm"
            )
        case .CalibrationRequiredAlarm,
             .CalibrationSuspicious2Alert:
            return LocalizedString(
                "Your calibration is due. Please perform a fingerstick blood glucose meter calibration now.",
                comment: "description for CalibrationRequiredAlarm"
            )
        case .SeriouslyLowAlarm:
            return LocalizedString(
                "Your sensor glucose value is too low. Please measure your glucose manually using your blood glucose meter.",
                comment: "description for SeriouslyLowAlarm"
            )
        case .SeriouslyHighAlarm:
            return LocalizedString(
                "Your sensor glucose value is too high. Please measure your glucose manually using your blood glucose meter.",
                comment: "description for SeriouslyHighAlarm"
            )
        case .CalibrationGracePeriodAlarm:
            return LocalizedString(
                "Your Transmitter is past due for Calibration. Sensor Glucose values will no longer be displayed.",
                comment: "description for CalibrationGracePeriodAlarm"
            )
        case .CalibrationExpiredAlarm:
            return LocalizedString(
                "A calibration has not been performed in 24 hours. Your system is now in re-initialization phase and you will have to perform 4 fingerstick calibration tests.",
                comment: "description for CalibrationExpiredAlarm"
            )
        case .InvalidClockAlarm:
            return LocalizedString(
                "Your transmitter has old or invalid date/time stamp.",
                comment: "description for InvalidClockAlarm"
            )
        case .VibrationCurrentAlarm:
            return LocalizedString(
                "Your transmitter has detected an issue with the vibration motor and can no longer provide vibe alerts. Please contact Eversense Customer Support for a replacement transmitter.",
                comment: "description for VibrationCurrentAlarm"
            )
        case .MSPAlarm:
            return LocalizedString(
                "Your sensor has passed day 365. Contact your health care provider to schedule a replacement.",
                comment: "description for MSPAlarm"
            )
        case .CalibrationFailedAlert:
            return LocalizedString(
                "Not enough data was collected after your calibration entry. Please enter a fingerstick blood glucose calibration now.",
                comment: "description for CalibrationFailedAlert"
            )
        case .CalibrationNowAlarm:
            return LocalizedString(
                "In 4 hours, your calibration will be past due and no glucose will be displayed. Please enter a fingerstick blood glucose calibration now.",
                comment: "description for CalibrationNowAlarm"
            )
        case .TransmitterEOL396:
            return LocalizedString(
                "Your transmitter is out of warranty and will no longer provide glucose values. Contact your distributor to order a new transmitter.",
                comment: "description for TransmitterEOL396"
            )
        case .TransmitterEOL330,
             .TransmitterEOL366,
             .TransmitterEOL395:
            return LocalizedString(
                "Your transmitter is out of warranty and will soon no longer provide glucose values. Contact your distributor to order a new transmitter.",
                comment: "description for TransmitterEOL"
            )
        case .BatteryErrorAlarm:
            return LocalizedString(
                "The system has detected a problem with your transmitter's battery. You can continue to use your system, but please contact Eversense Customer Support for a replacement transmitter.",
                comment: "description for BatteryErrorAlarm"
            )
        case .OneCal:
            return LocalizedString("The system requires calibration once a week.", comment: "description for OneCal")
        case .BatteryStatusAlarm:
            return LocalizedString(
                "Your transmitter battery has approximately 24 hours of life remaining.",
                comment: "description for BatteryStatusAlarm"
            )
        case .SensorConnection:
            return LocalizedString(
                "The connection between your sensor and transmitter is not stable. Please position your transmitter for better signal strength.",
                comment: "description for SensorConnection"
            )
        case .GeneralGlucoseSuspended,
             .TransmitterGlucoseStale,
             .TransmitterKeepAliveNotReceived:
            return LocalizedString(
                "Use your BG meter to monitor your glucose. Contact Eversense Customer Support if the issue persists.",
                comment: "description for GeneralGlucoseSuspended"
            )
        case .SensorGraceAlarm:
            return LocalizedString(
                "Your sensor life has expired. Please contact your health care provider to schedule a replacement.",
                comment: "description for SensorGraceAlarm"
            )
        case .SensorSyncConfirmedAlarm:
            return LocalizedString(
                "Your transmitter has synced with your sensor.",
                comment: "description for SensorSyncConfirmedAlarm"
            )
        case .IncompatibleTx,
             .InValidTx:
            return LocalizedString(
                "Incompatible transmitter detected. Please try again. If the error persists, contact Eversense Customer Support.",
                comment: "description for IncompatibleTx"
            )
        case .SensorFile:
            return LocalizedString(
                "Unable to download sensor files. Please try again. If the error persists, contact Eversense Customer Support.",
                comment: "description for SensorFile"
            )
        case .WarmUpPhaseCompleteAlert:
            return LocalizedString("Your 24-hour Warm-up Phase is complete.", comment: "description for WarmUpPhaseCompleteAlert")
        case .TxPairingError,
             .TxPairingErrorOnKeyInvalid:
            return LocalizedString(
                "Please try again. If the error persists, contact Eversense Customer Support.",
                comment: "description for TxPairingError"
            )
        case .TransmitterOrSensorConnectionLostDuringLinking:
            return LocalizedString(
                "Check the connection between the transmitter, app, and sensor.",
                comment: "description for TransmitterOrSensorConnectionLostDuringLinking"
            )
        default:
            return nil
        }
    }
}
