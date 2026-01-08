extension EversenseE3 {
    class SetPredictionLowThresholdResponse {}

    class SetPredictionLowThresholdPacket: BasePacket {
        typealias T = SetPredictionLowThresholdResponse

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
                memoryAddress: FlashMemory.lowGlucoseTarget,
                data: BinaryOperations.dataFrom16Bits(value: value)
            )
        }

        func parseResponse(data _: Data) -> SetPredictionLowThresholdResponse {
            SetPredictionLowThresholdResponse()
        }
    }
}
