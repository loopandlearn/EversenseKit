import LoopKit

public enum ConnectionStatus: UInt8 {
    case idle = 0
    case connecting = 1
    case connected = 2

    var title: String {
        switch self {
        case .idle:
            return LocalizedString("Idle", comment: "connection status idle")
        case .connecting:
            return LocalizedString("Connecting", comment: "connection status connecting")
        case .connected:
            return LocalizedString("Connected", comment: "connection status connected")
        }
    }
}

public struct EversenseCGMState: RawRepresentable, Equatable {
    public typealias RawValue = CGMManager.RawStateValue

    public init?(rawValue: RawValue) {
        alarms = []
        bleNameString = rawValue["bleNameString"] as? String ?? ""
        bleUUIDString = rawValue["bleUUIDString"] as? String
        isOnboarded = rawValue["isOnboarded"] as? Bool ?? false
        isSyncing = rawValue["isSyncing"] as? Bool ?? false
        version = rawValue["version"] as? String
        extVersion = rawValue["extVersion"] as? String
        communicationProtocol = rawValue["communicationProtocol"] as? Double ?? 0
        mmaFeatures = rawValue["mmaFeatures"] as? UInt8 ?? 0
        vibrateMode = rawValue["vibrateMode"] as? Bool
        dayStartTime = rawValue["dayStartTime"] as? Date ?? Date.defaultDayStartTime
        nightStartTime = rawValue["nightStartTime"] as? Date ?? Date.defaultNightStartTime
        delayBLEDisconnectionAlarm = rawValue["delayBLEDisconnectionAlarm"] as? TimeInterval ?? .seconds(180)
        isDelayBLEDisconnectionAlarmSupported = rawValue["isDelayBLEDisconnectionAlarmSupported"] as? Bool ?? false
        lastCalibration = rawValue["lastCalibration"] as? Date
        nextCalibration = rawValue["nextCalibration"] as? Date
        calibrationCount = rawValue["calibrationCount"] as? UInt16 ?? 0
        isGlucoseHighAlarmEnabled = rawValue["isGlucoseHighAlarmEnabled"] as? Bool ?? false
        lowGlucoseAlarmInMgDl = rawValue["lowGlucoseAlarmInMgDl"] as? UInt16 ?? 0
        highGlucoseAlarmInMgDl = rawValue["highGlucoseAlarmInMgDl"] as? UInt16 ?? 0
        isPredictionLowEnabled = rawValue["isPredictionLowEnabled"] as? Bool ?? false
        isPredictionHighEnabled = rawValue["isPredictionHighEnabled"] as? Bool ?? false
        predictionRisingInterval = rawValue["predictionRisingInterval"] as? TimeInterval
        predictionFallingInterval = rawValue["predictionFallingInterval"] as? TimeInterval
        isFallingRateEnabled = rawValue["isRateEnabled"] as? Bool ?? false
        isRisingRateEnabled = rawValue["isRisingRateEnabled"] as? Bool ?? false
        rateFallingThreshold = rawValue["rateFallingThreshold"] as? Double
        rateRisingThreshold = rawValue["rateRisingThreshold"] as? Double
        signalStrengthRaw = rawValue["signalStrengthRaw"] as? UInt16 ?? 0
        tempThresholdWarning = rawValue["tempThresholdWarning"] as? UInt8 ?? 68
        tempThresholdModeChange = rawValue["tempThresholdModeChange"] as? UInt8 ?? 52
        recentGlucoseInMgDl = rawValue["recentGlucoseInMgDl"] as? UInt16
        recentGlucoseDateTime = rawValue["recentGlucoseDateTime"] as? Date
        batteryPercentage = rawValue["batteryPercentage"] as? Int ?? -1

        username = rawValue["username"] as? String
        password = rawValue["password"] as? String
        accessToken = rawValue["accessToken"] as? String
        accessTokenExpiration = rawValue["accessTokenExpiration"] as? Date
        publicKeyV2 = rawValue["publicKeyV2"] as? Data
        privateKeyV2 = rawValue["privateKeyV2"] as? Data
        clientIdV2 = rawValue["clientIdV2"] as? Data
        certificateV2 = rawValue["certificateV2"] as? String
        fleetKeyPublicKeyV2 = rawValue["fleetKeyPublicKeyV2"] as? Data

        if let rawCalibrationMode = rawValue["calibrationMode"] as? CalibrationMode.RawValue {
            calibrationMode = CalibrationMode(rawValue: rawCalibrationMode) ?? .Default
        } else {
            calibrationMode = .Default
        }

        if let rawCalibrationPhase = rawValue["calibrationPhase"] as? CalibrationPhase.RawValue {
            calibrationPhase = CalibrationPhase(rawValue: rawCalibrationPhase) ?? .UNKNOWN
        } else {
            calibrationPhase = .UNKNOWN
        }

        if let rawSignalStrength = rawValue["signalStrength"] as? SignalStrength.RawValue {
            signalStrength = SignalStrength(rawValue: rawSignalStrength) ?? .NoSignal
        } else {
            signalStrength = .NoSignal
        }

        if let rawRecentGlucoseTrend = rawValue["recentGlucoseTrend"] as? GlucoseTrend.RawValue {
            recentGlucoseTrend = GlucoseTrend(rawValue: rawRecentGlucoseTrend) ?? .flat
        } else {
            recentGlucoseTrend = .flat
        }

        if let rawSecurity = rawValue["security"] as? SecurityType.RawValue {
            security = SecurityType(rawValue: rawSecurity) ?? .none
        } else {
            security = .none
        }

        if let rawCalibrationReadiness = rawValue["calibrationReadiness"] as? CalibrationReadiness.RawValue {
            calibrationReadiness = CalibrationReadiness(rawValue: rawCalibrationReadiness) ?? .Unknown
        } else {
            calibrationReadiness = .Unknown
        }

        do {
            if let activeAlarmsData = rawValue["activeAlarms"] as? Data {
                activeAlarms = try JSONDecoder().decode([ActiveAlarm].self, from: activeAlarmsData)
            } else {
                activeAlarms = []
            }
        } catch {
            EversenseLogger(category: "EversenseCGMState").error("Failed to decode activeAlarms - \(error.localizedDescription)")
            activeAlarms = []
        }
    }

    public var rawValue: RawValue {
        var value: [String: Any] = [:]

        value["bleNameString"] = bleNameString
        value["bleUUIDString"] = bleUUIDString
        value["isOnboarded"] = isOnboarded
        value["isSyncing"] = isSyncing
        value["version"] = version
        value["extVersion"] = extVersion
        value["communicationProtocol"] = communicationProtocol
        value["mmaFeatures"] = mmaFeatures
        value["vibrateMode"] = vibrateMode
        value["batteryPercentage"] = batteryPercentage
        value["signalStrength"] = signalStrength.rawValue
        value["signalStrengthRaw"] = signalStrengthRaw
        value["dayStartTime"] = dayStartTime
        value["nightStartTime"] = nightStartTime
        value["delayBLEDisconnectionAlarm"] = delayBLEDisconnectionAlarm
        value["isDelayBLEDisconnectionAlarmSupported"] = isDelayBLEDisconnectionAlarmSupported
        value["lastCalibration"] = lastCalibration
        value["nextCalibration"] = nextCalibration
        value["calibrationMode"] = calibrationMode.rawValue
        value["calibrationCount"] = calibrationCount
        value["calibrationPhase"] = calibrationPhase.rawValue
        value["calibrationReadiness"] = calibrationReadiness.rawValue
        value["isGlucoseHighAlarmEnabled"] = isGlucoseHighAlarmEnabled
        value["lowGlucoseAlarmInMgDl"] = lowGlucoseAlarmInMgDl
        value["highGlucoseAlarmInMgDl"] = highGlucoseAlarmInMgDl
        value["isPredictionLowEnabled"] = isPredictionLowEnabled
        value["isPredictionHighEnabled"] = isPredictionHighEnabled
        value["predictionRisingInterval"] = predictionRisingInterval
        value["predictionFallingInterval"] = predictionFallingInterval
        value["isFallingRateEnabled"] = isFallingRateEnabled
        value["isRisingRateEnabled"] = isRisingRateEnabled
        value["rateFallingThreshold"] = rateFallingThreshold
        value["rateRisingThreshold"] = rateRisingThreshold
        value["tempThresholdWarning"] = tempThresholdWarning
        value["tempThresholdModeChange"] = tempThresholdModeChange
        value["recentGlucoseInMgDl"] = recentGlucoseInMgDl
        value["recentGlucoseDateTime"] = recentGlucoseDateTime
        value["recentGlucoseTrend"] = recentGlucoseTrend.rawValue
        value["security"] = security.rawValue
        value["username"] = username
        value["password"] = password
        value["accessToken"] = accessToken
        value["accessTokenExpiration"] = accessTokenExpiration
        value["publicKeyV2"] = publicKeyV2
        value["privateKeyV2"] = privateKeyV2
        value["clientIdV2"] = clientIdV2
        value["certificateV2"] = certificateV2
        value["fleetKeyPublicKeyV2"] = fleetKeyPublicKeyV2

        do {
            value["activeAlarms"] = try JSONEncoder().encode(activeAlarms)
        } catch {
            EversenseLogger(category: "EversenseCGMState").error("Failed to encode activeAlarms - \(error.localizedDescription)")
        }

        return value
    }

    public var connectionStatus: ConnectionStatus = .idle
    public var bleUUIDString: String?
    public var bleNameString: String
    public var isOnboarded: Bool
    public var isSyncing: Bool
    public var version: String?
    public var extVersion: String?
    public var communicationProtocol: Double

    public var mmaFeatures: UInt8
    public var batteryPercentage: Int
    public var vibrateMode: Bool?

    public var signalStrength: SignalStrength
    public var signalStrengthRaw: UInt16

    var alarms: [TransmitterAlert]

    public var dayStartTime: Date
    public var nightStartTime: Date
    public var delayBLEDisconnectionAlarm: TimeInterval
    public var isDelayBLEDisconnectionAlarmSupported: Bool

    public var lastCalibration: Date?
    public var nextCalibration: Date?

    public var calibrationMode: CalibrationMode
    public var calibrationPhase: CalibrationPhase
    public var calibrationCount: UInt16
    public var calibrationReadiness: CalibrationReadiness

    public var isGlucoseHighAlarmEnabled: Bool
    public var lowGlucoseAlarmInMgDl: UInt16
    public var highGlucoseAlarmInMgDl: UInt16

    public var isPredictionLowEnabled: Bool
    public var isPredictionHighEnabled: Bool
    public var predictionFallingInterval: TimeInterval?
    public var predictionRisingInterval: TimeInterval?

    public var isFallingRateEnabled: Bool
    public var isRisingRateEnabled: Bool
    public var rateFallingThreshold: Double?
    public var rateRisingThreshold: Double?

    public var tempThresholdWarning: UInt8
    public var tempThresholdModeChange: UInt8

    public var recentGlucoseInMgDl: UInt16?
    public var recentGlucoseDateTime: Date?
    public var recentGlucoseTrend: GlucoseTrend

    public var activeAlarms: [ActiveAlarm]

    // Eversense 365
    public var security: SecurityType = .none
    public var username: String?
    public var password: String?
    public var accessToken: String?
    public var accessTokenExpiration: Date?

    public var publicKeyV2: Data?
    public var privateKeyV2: Data?
    public var clientIdV2: Data?
    public var certificateV2: String?
    public var fleetKeyPublicKeyV2: Data?

    public var isUSXLorOUSXL2: Bool {
        !(mmaFeatures == 0 || mmaFeatures == 255 || mmaFeatures < 1)
    }

    public var is365: Bool {
        !(security == .none)
    }

    public var modelStr: String? {
        if is365 {
            return LocalizedString("Eversense 365", comment: "Eversense 365 (1year)")
        }

        return LocalizedString("Eversense E3", comment: "Eversense E3")
    }

    public var debugDescription: String {
        [
            "Current timezone: \(TimeZone.current.identifier)"
        ].joined(separator: "\n")
    }
}
