extension EversenseE3 {
    class GetLogRangeResponse {
        public let rangeFrom: UInt32
        public let rangeTo: UInt32

        init(rangeFrom: UInt32, rangeTo: UInt32) {
            self.rangeFrom = rangeFrom
            self.rangeTo = rangeTo
        }
    }

    class GetLogRangePacket: BasePacket {
        typealias T = GetLogRangeResponse

        var responseType: UInt8 {
            type.getResponseId()
        }

        var responseId: UInt8? {
            nil
        }

        let type: LogRangeType
        init(type: LogRangeType) {
            self.type = type
        }

        func getRequestData() -> Data {
            var data = Data([type.getRequestId()])

            let checksum = BinaryOperations.generateChecksumCRC16(data: data)
            data.append(BinaryOperations.dataFrom16Bits(value: checksum))

            return data
        }

        /// Parsed response:
        /// 01 00 -> start index
        /// 23 00 -> final index
        func parseResponse(data: Data) -> EversenseE3.GetLogRangeResponse {
            let from: UInt32
            let to: UInt32

            if type == .bloodGlucose {
                from = UInt32(data[start]) | UInt32(data[start + 1]) << 8 | UInt32(data[start + 2]) << 16
                to = UInt32(data[start + 3]) | UInt32(data[start + 4]) << 8 | UInt32(data[start + 5]) << 16
            } else {
                from = UInt32(data[start]) | UInt32(data[start + 1]) << 8
                to = UInt32(data[start + 2]) | UInt32(data[start + 3]) << 8
            }

            return GetLogRangeResponse(rangeFrom: from, rangeTo: to)
        }
    }
}
