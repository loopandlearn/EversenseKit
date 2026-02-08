extension EversenseE3 {
    class GetAlertLogResponse {
        public let index: UInt32
        public let datetime: Date
        public let alarm: Alarm

        init(index: UInt32, datetime: Date, alarm: Alarm) {
            self.index = index
            self.datetime = datetime
            self.alarm = alarm
        }
    }

    class GetAlertLogPacket: BasePacket {
        typealias T = GetAlertLogResponse

        var responseType: UInt8 {
            PacketIds.readAllSensorGlucoseAlertsInSpecifiedRangeResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        private let index: UInt16
        init(index: UInt16) {
            self.index = index
        }

        func getRequestData() -> Data {
            var data = Data([PacketIds.readAllSensorGlucoseAlertsInSpecifiedRangeCommandId.rawValue])
            data.append(BinaryOperations.dataFrom16Bits(value: index))
            data.append(BinaryOperations.dataFrom16Bits(value: index))

            let checksum = BinaryOperations.generateChecksumCRC16(data: data)
            data.append(BinaryOperations.dataFrom16Bits(value: checksum))

            return data
        }

        func parseResponse(data: Data) -> EversenseE3.GetAlertLogResponse {
            let index = UInt32(data[start]) | UInt32(data[start + 1]) << 8
            let datetime = Date.fromComponents(
                date: BinaryOperations.toDateComponents(data: data, start: start + 2),
                time: BinaryOperations.toTimeComponents(data: data, start: start + 4)
            )

            return GetAlertLogResponse(
                index: index,
                datetime: datetime,
                alarm: Alarm(rawValue: data[start + 7]) ?? .unknown
            )
        }
    }
}
