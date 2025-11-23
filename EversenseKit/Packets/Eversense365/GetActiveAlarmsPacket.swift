extension Eversense365 {
    class GetActiveAlarmsResponse {
        let count: UInt8
        let alarms: [ActiveAlarm]

        init(count: UInt8, alarms: [ActiveAlarm]) {
            self.count = count
            self.alarms = alarms
        }
    }

    class GetActiveAlarmsPacket: BasePacket {
        typealias T = GetActiveAlarmsResponse

        var responseType: UInt8 {
            PacketIds.ReadResponseId.rawValue
        }

        var responseId: UInt8? {
            ReadIds.ActiveAlerts.rawValue
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.ReadCommandId.rawValue, ReadIds.ActiveAlerts.rawValue])
            return CryptoUtil.shared.encrypt(data: data)
        }

        /// Parsed message:
        /// 42 22 -> CmdType & CmdId
        /// 01 -> Blood glucose
        /// 01 01 01 -> Active alarm
        func parseResponse(data: Data) -> GetActiveAlarmsResponse {
            let count = data[Offset.NoOfAlerts]
            var alarms: [ActiveAlarm] = []

            for i in 0 ..< Int(count) {
                let offsetStart = i * 3 + 3
                guard data.count >= offsetStart + 2 else {
                    logger
                        .warning(
                            "Message has less alarms then expected - data: \(data.hexString()), count: \(count), offsetStart: \(offsetStart)"
                        )
                    break
                }

                alarms.append(ActiveAlarm(
                    code: data[offsetStart],
                    flag: data[offsetStart + 1],
                    priority: data[offsetStart + 2],
                ))
            }

            return GetActiveAlarmsResponse(
                count: count,
                alarms: alarms
            )
        }

        enum Offset {
            static let NoOfAlerts = 2

            // Offset within the chunk
            static let Code = 0
            static let Flag = 1
            static let Priority = 2
        }
    }
}
