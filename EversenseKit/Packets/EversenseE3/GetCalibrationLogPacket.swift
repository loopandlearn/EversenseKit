extension EversenseE3 {
    class GetCalibrationLogResponse {
        public let index: UInt32
        public let datetime: Date
        public let glucoseInMgDl: UInt16

        init(index: UInt32, datetime: Date, glucoseInMgDl: UInt16) {
            self.index = index
            self.datetime = datetime
            self.glucoseInMgDl = glucoseInMgDl
        }
    }

    class GetCalibrationLogPacket: BasePacket {
        typealias T = GetCalibrationLogResponse

        var responseType: UInt8 {
            PacketIds.readAllSensorGlucoseDataInSpecifiedRangeResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        private let index: UInt32
        init(index: UInt32) {
            self.index = index
        }

        func getRequestData() -> Data {
            var data = Data([PacketIds.readAllSensorGlucoseDataInSpecifiedRangeCommandId.rawValue])
            data.append(BinaryOperations.dataFrom24Bits(value: index))
            data.append(BinaryOperations.dataFrom24Bits(value: index))

            let checksum = BinaryOperations.generateChecksumCRC16(data: data)
            data.append(BinaryOperations.dataFrom16Bits(value: checksum))

            return data
        }

        func parseResponse(data: Data) -> GetCalibrationLogResponse {
            let index = UInt32(data[start]) | UInt32(data[start + 1]) << 8 | UInt32(data[start + 2]) << 16
            let datetime = Date.fromComponents(
                date: BinaryOperations.toDateComponents(data: data, start: start + 3),
                time: BinaryOperations.toTimeComponents(data: data, start: start + 5)
            )
            let glucoseInMgDl = UInt16(data[start + 7]) | UInt16(data[start + 8]) << 8

            return GetCalibrationLogResponse(
                index: index,
                datetime: datetime,
                glucoseInMgDl: glucoseInMgDl
            )
        }
    }
}
