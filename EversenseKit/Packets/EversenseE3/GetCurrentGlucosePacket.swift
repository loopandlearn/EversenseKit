import LoopKit

extension EversenseE3 {
    class GetCurrentGlucoseResponse {
        let datetime: Date
        let glucoseInMgDl: UInt16
        let trend: GlucoseTrend
        let raw: String

        init(datetime: Date, glucoseInMgDl: UInt16, trend: GlucoseTrend, raw: String) {
            self.datetime = datetime
            self.glucoseInMgDl = glucoseInMgDl
            self.trend = trend
            self.raw = raw
        }
    }

    class GetCurrentGlucosePacket: BasePacket {
        typealias T = GetCurrentGlucoseResponse

        var responseType: UInt8 {
            PacketIds.readSensorGlucoseResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            var data = Data([8])
            let checksum = BinaryOperations.generateChecksumCRC16(data: data)
            data.append(BinaryOperations.dataFrom16Bits(value: checksum))

            return data
        }

        func parseResponse(data: Data) -> GetCurrentGlucoseResponse {
            GetCurrentGlucoseResponse(
                datetime: Date.fromComponents(
                    date: BinaryOperations.toDateComponents(data: data, start: start + 3),
                    time: BinaryOperations.toTimeComponents(data: data, start: start + 5)
                ),
                glucoseInMgDl: UInt16(data[start + 8]) | (UInt16(data[start + 9]) << 8),
                trend: getTrend(value: data[start + 12]),
                raw: data.base64EncodedString()
            )
        }

        func getTrend(value: UInt8) -> GlucoseTrend {
            switch value {
            case 0:
                return .flat // STALE
            case 1:
                return .downDown
            case 2:
                return .down
            case 3:
                return .flat
            case 4:
                return .up
            case 5:
                return .upUp
            default:
                return .flat // STALE
            }
        }
    }
}
