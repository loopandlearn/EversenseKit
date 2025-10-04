extension Eversense365 {
    class SetRateFallingThresholdResponse {}

    class SetRateFallingThresholdPacket: BasePacket {
        typealias T = SetRateFallingThresholdResponse

        var responseType: UInt8 {
            PacketIds.WriteResponseId.rawValue
        }

        var responseId: UInt8? {
            WriteIds.RateFallingThreshold.rawValue
        }

        let value: UInt8
        init(value: UInt8) {
            self.value = value
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.WriteCommandId.rawValue, WriteIds.RateFallingThreshold.rawValue, value])
            return CryptoUtil.shared.encrypt(data: data)
        }

        func parseResponse(data _: Data) -> SetRateFallingThresholdResponse {
            SetRateFallingThresholdResponse()
        }
    }
}
