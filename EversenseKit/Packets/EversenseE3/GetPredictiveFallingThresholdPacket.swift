extension EversenseE3 {
    class GetPredictiveFallingThresholdResponse {
        let value: UInt16

        init(value: UInt16) {
            self.value = value
        }
    }

    class GetPredictiveFallingThresholdPacket: BasePacket {
        typealias T = GetPredictiveFallingThresholdResponse

        var responseType: UInt8 {
            PacketIds.readTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readTwoByteSerialFlashRegister(memoryAddress: FlashMemory.lowGlucoseTarget)
        }

        func parseResponse(data: Data) -> GetPredictiveFallingThresholdResponse {
            GetPredictiveFallingThresholdResponse(
                value: UInt16(data[start]) | (UInt16(data[start + 1]) << 8)
            )
        }
    }
}
