extension EversenseE3 {
    class GetNextCalibrationTimeResponse {
        let time: DateComponents

        init(time: DateComponents) {
            self.time = time
        }
    }

    class GetNextCalibrationTimePacket: BasePacket {
        typealias T = GetNextCalibrationTimeResponse

        var responseType: UInt8 {
            PacketIds.readTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readTwoByteSerialFlashRegister(memoryAddress: FlashMemory.nextCalibrationTime)
        }

        func parseResponse(data: Data) -> GetNextCalibrationTimeResponse {
            GetNextCalibrationTimeResponse(
                time: BinaryOperations.toTimeComponents(data: data, start: start)
            )
        }
    }
}
