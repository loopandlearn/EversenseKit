struct TransmitterSettings {
    let vibrationMode: Bool

    let enableGlucoseHighAlerts: Bool
    let glucoseHighInMgDl: UInt16
    let glucoseLowInMgDl: UInt16

    let isFallingRateEnabled: Bool
    let isRisingRateEnabled: Bool
    let rateFallingThreshold: UInt8
    let rateRisingThreshold: UInt8
}
