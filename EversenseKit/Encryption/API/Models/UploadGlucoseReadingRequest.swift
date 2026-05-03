struct UploadGlucoseReadingRequest: Codable {
    let SensorId: String
    let TransmitterId: String
    let Timestamp: String
    let CurrentGlucoseValue: Int
    let CurrentGlucoseDateTime: String
    let FWVersion: String
    let EssentialLog: String
}
