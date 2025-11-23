extension Eversense365 {
    class GetPatientSettingsResponse {
        let vibrateMode: Bool
        let isGlucoseHighAlarmEnabled: Bool
        let lowGlucoseAlarmInMgDl: UInt16
        let highGlucoseAlarmInMgDl: UInt16
        let isPredictionLowEnabled: Bool
        let isPredictionHighEnabled: Bool
        let predictionFallingInterval: TimeInterval
        let predictionRisingInterval: TimeInterval
        let isFallingRateEnabled: Bool
        let isRisingRateEnabled: Bool
        let rateFallingThreshold: Double
        let rateRisingThreshold: Double

        init(
            vibrateMode: Bool,
            isGlucoseHighAlarmEnabled: Bool,
            lowGlucoseAlarmInMgDl: UInt16,
            highGlucoseAlarmInMgDl: UInt16,
            isPredictionLowEnabled: Bool,
            isPredictionHighEnabled: Bool,
            predictionFallingInterval: TimeInterval,
            predictionRisingInterval: TimeInterval,
            isFallingRateEnabled: Bool,
            isRisingRateEnabled: Bool,
            rateFallingThreshold: Double,
            rateRisingThreshold: Double
        ) {
            self.vibrateMode = vibrateMode
            self.isGlucoseHighAlarmEnabled = isGlucoseHighAlarmEnabled
            self.lowGlucoseAlarmInMgDl = lowGlucoseAlarmInMgDl
            self.highGlucoseAlarmInMgDl = highGlucoseAlarmInMgDl
            self.isPredictionLowEnabled = isPredictionLowEnabled
            self.isPredictionHighEnabled = isPredictionHighEnabled
            self.predictionFallingInterval = predictionFallingInterval
            self.predictionRisingInterval = predictionRisingInterval
            self.isFallingRateEnabled = isFallingRateEnabled
            self.isRisingRateEnabled = isRisingRateEnabled
            self.rateFallingThreshold = rateFallingThreshold
            self.rateRisingThreshold = rateRisingThreshold
        }
    }

    class GetPatientSettingsPacket: BasePacket {
        typealias T = GetPatientSettingsResponse

        var responseType: UInt8 {
            PacketIds.ReadResponseId.rawValue
        }

        var responseId: UInt8? {
            ReadIds.PatientInformation.rawValue
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.ReadCommandId.rawValue, ReadIds.PatientInformation.rawValue])
            return CryptoUtil.shared.encrypt(data: data)
        }

        /// Message parsed:
        /// 42 21 -> CmdType & CmdId
        /// 44 33 30 36 33 36 36 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 -> Transmitter name
        /// 38 2E 30 2E 34 00 00 00 00 00 00 00 00 00 00 00 -> Recent MMA Version
        /// 00 -> Is clinical mode enabled
        /// 00 -> Is do not Disturb Enabled
        /// 2C 01 -> BLE connect time in sec -> 300s
        /// 46 00 -> Low sugar target in mg/dl
        /// B4 00 -> High sugar target in mg/dl
        /// 00 -> Alarm rate falling enabled
        /// 19 -> Alarm rate falling threshold
        /// 00 -> Alarm rate rising enabled
        /// 19 -> Alarm rate rising threshold
        /// 00 -> Alarm Predictive Low enabled
        /// 14 -> Alarm Predictive Low Time
        /// 00 -> Alarm Predictive High enabled
        /// 14 -> Alarm Predictive High Time
        /// 01 -> Alarm High Glucose enabled
        /// FA 00 -> Alarm High Glucose Threshold
        /// 1E -> Alarm High Glucose Repeat Interval
        /// 41 00 -> Alarm Low Glucose Threshold
        /// 0F -> Alarm Low Glucose Repeat Interval
        /// 34 -> Battery Temp Thresh Mode Change
        /// 44 -> Battery Temp Thresh Warn
        func parseResponse(data: Data) -> GetPatientSettingsResponse {
            GetPatientSettingsResponse(
                vibrateMode: data[Offset.IS_DO_NOT_DISTURB_ENABLED] != 0x00,
                isGlucoseHighAlarmEnabled: data[Offset.ALARM_HIGH_GLUCOSE_ENABLED] != 0x00,
                lowGlucoseAlarmInMgDl: UInt16(data[Offset.ALARM_LOW_GLUCOSE_THRESHOLD]) |
                    (UInt16(data[Offset.ALARM_LOW_GLUCOSE_THRESHOLD + 1]) << 8),
                highGlucoseAlarmInMgDl: UInt16(data[Offset.ALARM_HIGH_GLUCOSE_THRESHOLD]) |
                    (UInt16(data[Offset.ALARM_HIGH_GLUCOSE_THRESHOLD + 1]) << 8),
                isPredictionLowEnabled: data[Offset.ALARM_PREDICTIVE_LOW_ENABLED] != 0x00,
                isPredictionHighEnabled: data[Offset.ALARM_PREDICTIVE_HIGH_ENABLED] != 0x00,
                predictionFallingInterval: .minutes(Double(data[Offset.ALARM_PREDICTIVE_LOW_TIME])),
                predictionRisingInterval: .minutes(Double(data[Offset.ALARM_PREDICTIVE_HIGH_TIME])),
                isFallingRateEnabled: data[Offset.ALARM_RATE_FALLING_ENABLED] != 0x00,
                isRisingRateEnabled: data[Offset.ALARM_RATE_RISING_ENABLED] != 0x00,
                rateFallingThreshold: Double(data[Offset.ALARM_RATE_FALLING_THRESHOLD]) / 10,
                rateRisingThreshold: Double(data[Offset.ALARM_RATE_RISING_THRESHOLD]) / 10
            )
        }

        enum Offset {
            static let TRANSMITTER_NAME_START = 2
            static let TRANSMITTER_NAME_END = 27

            static let RECENT_MMA_VERSION_START = 27
            static let RECENT_MMA_VERSION_END = 43

            static let IS_CLINICAL_MODE_ENABLED = 43
            static let IS_DO_NOT_DISTURB_ENABLED = 44

            static let BLE_CONNECT_TIME_START = 45
            static let BLE_CONNECT_TIME_END = 47

            static let LOW_SUGAR_TARGET_START = 47
            static let LOW_SUGAR_TARGET_END = 49

            static let HIGH_SUGAR_TARGET_START = 49
            static let HIGH_SUGAR_TARGET_END = 51

            static let ALARM_RATE_FALLING_ENABLED = 51
            static let ALARM_RATE_FALLING_THRESHOLD = 52
            static let ALARM_RATE_RISING_ENABLED = 53
            static let ALARM_RATE_RISING_THRESHOLD = 54
            static let ALARM_PREDICTIVE_LOW_ENABLED = 55
            static let ALARM_PREDICTIVE_LOW_TIME = 56
            static let ALARM_PREDICTIVE_HIGH_ENABLED = 57
            static let ALARM_PREDICTIVE_HIGH_TIME = 58
            static let ALARM_HIGH_GLUCOSE_ENABLED = 59
            static let ALARM_HIGH_GLUCOSE_THRESHOLD = 60
            static let ALARM_HIGH_GLUCOSE_REPEAT_INTERVAL = 62
            static let ALARM_LOW_GLUCOSE_THRESHOLD = 63
            static let ALARM_LOW_GLUCOSE_REPEAT_INTERVAL = 65
            static let BATTERY_TEMP_THRESH_MODE_CHANGE = 66
            static let BATTERY_TEMP_THRESH_WARN = 67
        }
    }
}
