struct UploadCurrentGlucoseRequest: Codable {
    let CurrentGlucose: Int
    let CGTime: String
    let GlucoseTrend: Int
    let SignalStrength: Int
    let BatteryStrength: Int
    let IsTransmitterConnected: Bool
}
