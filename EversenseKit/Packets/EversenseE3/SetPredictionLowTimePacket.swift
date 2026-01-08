extension EversenseE3 {
    class SetPredictionLowTimeResponse {}

    class SetPredictionLowTimePacket: BasePacket {
        typealias T = SetPredictionLowTimeResponse

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
                memoryAddress: FlashMemory.predictiveFallingTime,
                data: Data([value])
            )
        }

        func parseResponse(data _: Data) -> SetPredictionLowTimeResponse {
            SetPredictionLowTimeResponse()
        }
    }
}
