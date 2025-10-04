extension Eversense365 {
    class SetRateRisingThresholdResponse {}

    class SetRateRisingThresholdPacket: BasePacket {
        typealias T = SetRateRisingThresholdResponse

        var responseType: UInt8 {
            PacketIds.WriteResponseId.rawValue
        }

        var responseId: UInt8? {
            WriteIds.RateRisingThreshold.rawValue
        }

        let value: UInt8
        init(value: UInt8) {
            self.value = value
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.WriteCommandId.rawValue, WriteIds.RateRisingThreshold.rawValue, value])
            return CryptoUtil.shared.encrypt(data: data)
        }

        func parseResponse(data _: Data) -> SetRateRisingThresholdResponse {
            SetRateRisingThresholdResponse()
        }
    }
}
