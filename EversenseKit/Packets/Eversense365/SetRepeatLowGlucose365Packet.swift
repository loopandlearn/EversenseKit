extension Eversense365 {
    class SetRepeatLowGlucoseResponse {}

    class SetRepeatLowGlucosePacket: BasePacket {
        typealias T = SetRepeatLowGlucoseResponse

        var responseType: UInt8 {
            PacketIds.WriteResponseId.rawValue
        }

        var responseId: UInt8? {
            WriteIds.LowGlucoseAlarmRepeat.rawValue
        }

        let interval: TimeInterval
        init(interval: TimeInterval) {
            self.interval = interval
        }

        func getRequestData() -> Data {
            let data = Data([
                PacketIds.WriteCommandId.rawValue,
                WriteIds.LowGlucoseAlarmRepeat.rawValue,
                UInt8(interval.minutes)
            ])

            return CryptoUtil.shared.encrypt(data: data)
        }

        func parseResponse(data _: Data) -> SetRepeatLowGlucoseResponse {
            SetRepeatLowGlucoseResponse()
        }
    }
}
