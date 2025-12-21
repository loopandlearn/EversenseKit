extension EversenseE3 {
    class GetInsertionTimeResponse {
        let insertionTime: DateComponents

        init(insertionTime: DateComponents) {
            self.insertionTime = insertionTime
        }
    }

    class GetInsertionTimePacket: BasePacket {
        typealias T = GetInsertionTimeResponse

        var responseType: UInt8 {
            PacketIds.readTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readTwoByteSerialFlashRegister(memoryAddress: FlashMemory.sensorInsertionTime)
        }

        func parseResponse(data: Data) -> GetInsertionTimeResponse {
            GetInsertionTimeResponse(
                insertionTime: BinaryOperations.toTimeComponents(data: data, start: start)
            )
        }
    }
}
