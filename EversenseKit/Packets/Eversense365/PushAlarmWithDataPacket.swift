extension Eversense365 {
    class PushAlarmWithDataResponse {
        let alarm: ActiveAlarm
        let datetime: Date

        init(alarm: ActiveAlarm, datetime: Date) {
            self.alarm = alarm
            self.datetime = datetime
        }
    }

    class PushAlarmWithDataPacket: BasePacket {
        typealias T = PushAlarmWithDataResponse

        var responseType: UInt8 {
            PacketIds.NotificationId.rawValue
        }

        var responseId: UInt8? {
            PushIds.AlarmWithData.rawValue
        }

        func getRequestData() -> Data {
            // Unused
            Data()
        }

        /// Parsed message:
        /// 44 03 -> CmdType & CmdId
        /// 06 -> Alarm code
        /// 00 08 b2 e1 c4 00 00 00 -> Alarm datetime
        /// 03 00 00 00 00 03 00 00 00 00 00 00 00 00 00 00 -> Alarm data
        func parseResponse(data: Data) -> Eversense365.PushAlarmWithDataResponse {
            PushAlarmWithDataResponse(
                alarm: ActiveAlarm(
                    code: Alarm(rawValue: data[3]) ?? .unknown,
                    codeRaw: data[3],
                    flag: 0,
                    priority: 0
                ),
                datetime: Date.fromUnix2000(data: data.subdata(in: 4 ..< 12)),
            )
        }
    }
}
