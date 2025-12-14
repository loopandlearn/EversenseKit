enum MessageCoder {
    static func messageCodeForPredictiveAlertFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .PredictiveLowAlarm
        case 4: return .PredictiveHighAlarm
        default: return nil
        }
    }

    static func messageCodeForTransmitterStatusAlertFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .CriticalFaultAlarm
        case 4: return .InvalidSensorAlarm
        case 8: return .InvalidClockAlarm
        case 32: return .VibrationCurrentAlarm
        case 64: return .unknown // .SensorAgedOutAlarm
        case 128: return .unknown // .SensorOnHoldAlarm
        default: return nil
        }
    }

    static func messageCodeForRateAlertFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .RateFallingAlarm
        case 2: return .RateRisingAlarm
        default: return nil
        }
    }

    static func messageCodeForTransmitterBatteryAlertFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .EmptyBatteryAlarm
        case 2: return .VeryLowBatteryAlarm
        case 4: return .EmptyBatteryAlarm
        case 8: return .BatteryErrorAlarm
        default: return nil
        }
    }

    static func messageCodeForSensorReadAlertFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .SeriouslyHighAlarm
        case 2: return .SeriouslyLowAlarm
        case 4: return .unknown // .HighAmbientLightAlarm
        case 8: return .unknown // .mepAlarm
        case 16: return .SensorTemperatureAlarm
        case 32: return .SensorLowTemperatureAlarm
        case 64: return .ReaderTemperatureAlarm
        case 128: return .MSPAlarm
        default: return nil
        }
    }

    static func messageCodeForSensorReplacementFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .SensorRetiredAlarm
        case 2: return .SensorRetiringSoon1Alarm
        case 4: return .SensorRetiringSoon1Alarm
        case 8: return .SensorRetiringSoon3Alarm
        case 16: return .SensorRetiringSoon4Alarm
        case 32: return .SensorRetiringSoon5Alarm
        case 64: return .SensorRetiringSoon6Alarm
        case 128: return .unknown // .SensorPrematureReplacementAlarm
        default: return nil
        }
    }

    static func messageCodeForSensorCalibrationFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .CalibrationGracePeriodAlarm
        case 2: return .CalibrationExpiredAlarm
        case 4: return .CalibrationGracePeriodAlarm // "CalibrationRequiredAlarm" not in enum
        case 16: return .CalibrationGracePeriodAlarm // "CalibrationFailedAlert" not in enum
        case 32: return .CalibrationGracePeriodAlarm // "CalibrationSuspiciousAlert" not in enum
        case 64: return .CalibrationGracePeriodAlarm // "CalibrationNowAlarm" not in enum
        case 128: return .CalibrationGracePeriodAlarm // "CalibrationSuspicious2Alert" not in enum
        default: return nil
        }
    }

    static func messageCodeForSensorHardwareAndAlertFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .unknown // .sensorErrorAlarm
        case 2: return .SensorAwolAlarm
        case 4: return .unknown // .SensorStability
        case 8: return .unknown // .edrAlarm0
        case 16: return .unknown // .edrAlarm1
        case 32: return .unknown // .edrAlarm2
        case 64: return .unknown // .edrAlarm3
        case 128: return .unknown // .edrAlarm4
        default: return nil
        }
    }

    static func messageCodeForTransmitterEOLAlertFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .TransmitterEOL396
        case 2: return .TransmitterEOL366
        case 4: return .TransmitterEOL330
        case 8: return .TransmitterEOL395
        default: return nil
        }
    }

    static func messageCodeForSensorReplacementFlags2(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .SensorRetiringSoon7Alarm
        default: return nil
        }
    }

    static func messageCodeForCalibrationSwitchFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .OneCal
        case 2: return .TwoCal
        default: return nil
        }
    }

    static func messageCodeForGlucoseLevelAlarmFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .LowGlucoseAlarm
        case 2: return .HighGlucoseAlarm
        default: return nil
        }
    }

    static func messageCodeForGlucoseLevelAlertFlags(_ value: UInt8) -> Alarm? {
        switch value {
        case 1: return .LowGlucoseAlarm
        case 2: return .HighGlucoseAlarm
        default: return nil
        }
    }
}
