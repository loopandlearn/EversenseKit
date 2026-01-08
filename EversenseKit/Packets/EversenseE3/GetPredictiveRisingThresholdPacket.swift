extension EversenseE3 {
    class GetPredictiveRisingThresholdResponse {
        let value: UInt16

        init(value: UInt16) {
            self.value = value
        }
    }

    class GetPredictiveRisingThresholdPacket: BasePacket {
        typealias T = GetPredictiveRisingThresholdResponse

        var responseType: UInt8 {
            PacketIds.readTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readTwoByteSerialFlashRegister(memoryAddress: FlashMemory.highGlucoseTarget)
        }

        func parseResponse(data: Data) -> GetPredictiveRisingThresholdResponse {
            GetPredictiveRisingThresholdResponse(
                value: UInt16(data[start]) | (UInt16(data[start + 1]) << 8)
            )
        }
    }
}
