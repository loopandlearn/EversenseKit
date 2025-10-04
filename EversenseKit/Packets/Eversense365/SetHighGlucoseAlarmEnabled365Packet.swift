extension Eversense365 {
    class SetHighGlucoseAlarmEnabledResponse {}

    class SetHighGlucoseAlarmEnabledPacket: BasePacket {
        typealias T = SetHighGlucoseAlarmEnabledResponse

        var responseType: UInt8 {
            PacketIds.WriteResponseId.rawValue
        }

        var responseId: UInt8? {
            WriteIds.HighGlucoseAlarmEnable.rawValue
        }

        let enabled: Bool
        init(enabled: Bool) {
            self.enabled = enabled
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.WriteCommandId.rawValue, WriteIds.HighGlucoseAlarmEnable.rawValue, enabled ? 1 : 0])
            return CryptoUtil.shared.encrypt(data: data)
        }

        func parseResponse(data _: Data) -> SetHighGlucoseAlarmEnabledResponse {
            SetHighGlucoseAlarmEnabledResponse()
        }
    }
}
