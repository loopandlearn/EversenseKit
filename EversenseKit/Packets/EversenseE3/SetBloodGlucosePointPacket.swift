extension EversenseE3 {
    class SetBloodGlucosePointResponse {}

    class SetBloodGlucosePointPacket: BasePacket {
        typealias T = SetBloodGlucosePointResponse

        var responseType: UInt8 {
            PacketIds.sendBloodGlucoseDataResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        private let timestamp: Date
        private let glucoseInMgDl: UInt16
        init(glucoseInMgDl: UInt16, timestamp: Date) {
            self.glucoseInMgDl = glucoseInMgDl
            self.timestamp = timestamp
        }

        func getRequestData() -> Data {
            var data = Data([PacketIds.sendBloodGlucoseDataWithTwoTimestampsCommandId.rawValue])
            data.append(timestamp.toUnix2000())
            data.append(Date.now.toUnix2000())
            data.append(BinaryOperations.dataFrom16Bits(value: glucoseInMgDl))
            data.append(Data([0x00, 0x00, 0x00, 0x55]))

            let checksum = BinaryOperations.generateChecksumCRC16(data: data)
            data.append(BinaryOperations.dataFrom16Bits(value: checksum))

            return data
        }

        func parseResponse(data _: Data) -> SetBloodGlucosePointResponse {
            SetBloodGlucosePointResponse()
        }
    }
}
