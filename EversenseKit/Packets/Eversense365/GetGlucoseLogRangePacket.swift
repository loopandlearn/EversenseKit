extension Eversense365 {
    class GetGlucoseLogRangeResponse {
        let rangeFrom: UInt32
        let rangeTo: UInt32

        init(rangeFrom: UInt32, rangeTo: UInt32) {
            self.rangeFrom = rangeFrom
            self.rangeTo = rangeTo
        }
    }

    class GetGlucoseLogRangePacket: BasePacket {
        typealias T = GetGlucoseLogRangeResponse

        var responseType: UInt8 {
            PacketIds.ReadResponseId.rawValue
        }

        var responseId: UInt8? {
            readId
        }

        private let readId: UInt8
        init(communicationVersion: Double) {
            if communicationVersion >= 1.06 {
                readId = ReadIds.GetLogRange.rawValue
            } else {
                readId = ReadIds.GetLogRangeOld.rawValue
            }
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.ReadCommandId.rawValue, readId, LogTypes.Glucose.rawValue])
            return CryptoUtil.shared.encrypt(data: data)
        }

        /// Parsed message:
        /// 42 38 -> CmdType & CmdId
        /// 06 -> Blood glucose
        /// 00 00 00 00 -> From range
        /// 00 00 00 00 -> To range
        func parseResponse(data: Data) -> GetGlucoseLogRangeResponse {
            GetGlucoseLogRangeResponse(
                rangeFrom: UInt32(data.subdata(in: 3 ..< 7).toUInt64()),
                rangeTo: UInt32(data.subdata(in: 7 ..< 11).toUInt64())
            )
        }
    }
}
