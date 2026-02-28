extension Eversense365 {
    class SetRepeatHighGlucoseResponse {}

    class SetRepeatHighGlucosePacket: BasePacket {
        typealias T = SetRepeatHighGlucoseResponse

        var responseType: UInt8 {
            PacketIds.WriteResponseId.rawValue
        }

        var responseId: UInt8? {
            WriteIds.HighGlucoseAlarmRepeat.rawValue
        }

        let interval: TimeInterval
        init(interval: TimeInterval) {
            self.interval = interval
        }

        func getRequestData() -> Data {
            let data = Data([
                PacketIds.WriteCommandId.rawValue,
                WriteIds.HighGlucoseAlarmRepeat.rawValue,
                UInt8(interval.minutes)
            ])

            return CryptoUtil.shared.encrypt(data: data)
        }

        func parseResponse(data _: Data) -> SetRepeatHighGlucoseResponse {
            SetRepeatHighGlucoseResponse()
        }
    }
}
