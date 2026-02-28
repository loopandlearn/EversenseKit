struct TransmitterSettings {
    let vibrationMode: Bool

    let glucoseHighEnabled: Bool
    let glucoseHighInMgDl: UInt16
    let glucoseLowInMgDl: UInt16

    let rateFallingEnabled: Bool
    let rateRisingEnabled: Bool
    let rateFallingThreshold: UInt8
    let rateRisingThreshold: UInt8

    let predictiveHighEnabled: Bool
    let predictiveHighThreshold: UInt16
    let predictiveHighTime: TimeInterval
    let predictiveLowEnabled: Bool
    let predictiveLowThreshold: UInt16
    let predictiveLowTime: TimeInterval

    let repeatAlarmLow: TimeInterval
    let repeatAlarmHigh: TimeInterval
    let bleDisconnect: TimeInterval
}
