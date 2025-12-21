extension EversenseE3 {
    class GetInsertionDateResponse {
        let insertionDate: DateComponents

        init(insertionDate: DateComponents) {
            self.insertionDate = insertionDate
        }
    }

    class GetInsertionDatePacket: BasePacket {
        typealias T = GetInsertionDateResponse

        var responseType: UInt8 {
            PacketIds.readTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readTwoByteSerialFlashRegister(memoryAddress: FlashMemory.sensorInsertionDate)
        }

        func parseResponse(data: Data) -> EversenseE3.GetInsertionDateResponse {
            GetInsertionDateResponse(
                insertionDate: BinaryOperations.toDateComponents(data: data, start: start)
            )
        }
    }
}
