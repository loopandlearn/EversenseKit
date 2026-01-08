extension EversenseE3 {
    class SetPredictionHighTimeResponse {}

    class SetPredictionHighTimePacket: BasePacket {
        typealias T = SetPredictionHighTimeResponse

        var responseType: UInt8 {
            PacketIds.writeSingleByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        let value: UInt8
        init(time: TimeInterval) {
            value = UInt8(time.minutes)
        }

        func getRequestData() -> Data {
            CommandOperations.writeSingleByteSerialFlashRegister(
                memoryAddress: FlashMemory.predictiveRisingTime,
                data: Data([value])
            )
        }

        func parseResponse(data _: Data) -> SetPredictionHighTimeResponse {
            SetPredictionHighTimeResponse()
        }
    }
}
