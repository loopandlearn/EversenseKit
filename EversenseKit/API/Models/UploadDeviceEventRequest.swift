struct UploadDeviceEventRequest: Codable {
    let deviceType: String
    let deviceName: String
    let deviceID: String
    let offsetBytes: String
    let sgBytes: String
    let mgBytes: String
    let patientBytes: String
    let alertBytes: String
    let algorithmVersion: String
}
