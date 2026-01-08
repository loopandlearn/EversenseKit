extension EversenseE3 {
    class SetPredictionHighThresholdResponse {}

    class SetPredictionHighThresholdPacket: BasePacket {
        typealias T = SetPredictionHighThresholdResponse

        var responseType: UInt8 {
            PacketIds.writeTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        let value: UInt16
        init(value: UInt16) {
            self.value = value
        }

        func getRequestData() -> Data {
            CommandOperations.writeTwoByteSerialFlashRegister(
                memoryAddress: FlashMemory.highGlucoseTarget,
                data: BinaryOperations.dataFrom16Bits(value: value)
            )
        }

        func parseResponse(data _: Data) -> SetPredictionHighThresholdResponse {
            SetPredictionHighThresholdResponse()
        }
    }
}
