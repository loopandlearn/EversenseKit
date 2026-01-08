extension EversenseE3 {
    class GetNextCalibrationDateResponse {
        let date: DateComponents

        init(date: DateComponents) {
            self.date = date
        }
    }

    class GetNextCalibrationDatePacket: BasePacket {
        typealias T = GetNextCalibrationDateResponse

        var responseType: UInt8 {
            PacketIds.readTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readTwoByteSerialFlashRegister(memoryAddress: FlashMemory.nextCalibrationDate)
        }

        func parseResponse(data: Data) -> GetNextCalibrationDateResponse {
            GetNextCalibrationDateResponse(
                date: BinaryOperations.toDateComponents(data: data, start: start)
            )
        }
    }
}
