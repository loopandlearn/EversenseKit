extension Eversense365 {
    class SetVibrateModeResponse {}

    class SetVibrateModePacket: BasePacket {
        typealias T = SetVibrateModeResponse

        var responseType: UInt8 {
            PacketIds.WriteResponseId.rawValue
        }

        var responseId: UInt8? {
            WriteIds.VibrateMode.rawValue
        }

        let enabled: Bool
        init(enabled: Bool) {
            self.enabled = enabled
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.WriteCommandId.rawValue, WriteIds.VibrateMode.rawValue, enabled ? 1 : 0])
            return CryptoUtil.shared.encrypt(data: data)
        }

        func parseResponse(data _: Data) -> SetVibrateModeResponse {
            SetVibrateModeResponse()
        }
    }
}
