extension EversenseE3 {
    class GetLowGlucoseRepeatIntervalResponse {
        let interval: TimeInterval

        init(interval: TimeInterval) {
            self.interval = interval
        }
    }

    class GetLowGlucoseRepeatIntervalPacket: BasePacket {
        typealias T = GetLowGlucoseRepeatIntervalResponse

        var responseType: UInt8 {
            PacketIds.readSingleByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readSingleByteSerialFlashRegister(memoryAddress: FlashMemory.lowGlucoseAlarmRepeatIntervalDay)
        }

        func parseResponse(data: Data) -> GetLowGlucoseRepeatIntervalResponse {
            GetLowGlucoseRepeatIntervalResponse(
                interval: TimeInterval(minutes: Double(data[start]))
            )
        }
    }
}
