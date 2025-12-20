extension EversenseE3 {
    class GetCalibrationLogResponse {
        public let index: UInt32
        public let datetime: Date
        public let glucoseInMgDl: UInt16
        public let flag: CalibrationFlag

        init(index: UInt32, datetime: Date, glucoseInMgDl: UInt16, flag: CalibrationFlag) {
            self.index = index
            self.datetime = datetime
            self.glucoseInMgDl = glucoseInMgDl
            self.flag = flag
        }
    }

    class GetCalibrationLogPacket: BasePacket {
        typealias T = GetCalibrationLogResponse

        var responseType: UInt8 {
            PacketIds.readLogOfBloodGlucoseDataInSpecifiedRangeResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        private let index: UInt16
        init(index: UInt16) {
            self.index = index
        }

        func getRequestData() -> Data {
            var data = Data([PacketIds.readLogOfBloodGlucoseDataInSpecifiedRangeCommandId.rawValue])
            data.append(BinaryOperations.dataFrom16Bits(value: index))
            data.append(BinaryOperations.dataFrom16Bits(value: index))

            let checksum = BinaryOperations.generateChecksumCRC16(data: data)
            data.append(BinaryOperations.dataFrom16Bits(value: checksum))

            return data
        }

        func parseResponse(data: Data) -> GetCalibrationLogResponse {
            let index = UInt32(data[start]) | UInt32(data[start + 1]) << 8
            let datetime = Date.fromComponents(
                date: BinaryOperations.toDateComponents(data: data, start: start + 2),
                time: BinaryOperations.toTimeComponents(data: data, start: start + 4)
            )

            return GetCalibrationLogResponse(
                index: index,
                datetime: datetime,
                glucoseInMgDl: UInt16(data[start + 6]) | UInt16(data[start + 8]) << 7,
                flag: CalibrationFlag(rawValue: data[start + 9]) ?? .UNKNOWN_FAILURE
            )
        }
    }
}
