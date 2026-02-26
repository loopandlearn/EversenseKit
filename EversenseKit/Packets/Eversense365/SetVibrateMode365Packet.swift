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

        let silenced: Bool
        init(silenced: Bool) {
            self.silenced = silenced
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.WriteCommandId.rawValue, WriteIds.VibrateMode.rawValue, silenced ? 0 : 1])
            return CryptoUtil.shared.encrypt(data: data)
        }

        func parseResponse(data _: Data) -> SetVibrateModeResponse {
            SetVibrateModeResponse()
        }
    }
}
