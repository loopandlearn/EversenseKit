extension EversenseE3 {
    class GetHighGlucoseRepeatIntervalResponse {
        let interval: TimeInterval

        init(interval: TimeInterval) {
            self.interval = interval
        }
    }

    class GetHighGlucoseRepeatIntervalPacket: BasePacket {
        typealias T = GetHighGlucoseRepeatIntervalResponse

        var responseType: UInt8 {
            PacketIds.readSingleByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readSingleByteSerialFlashRegister(memoryAddress: FlashMemory.highGlucoseAlarmRepeatIntervalDay)
        }

        func parseResponse(data: Data) -> GetHighGlucoseRepeatIntervalResponse {
            GetHighGlucoseRepeatIntervalResponse(
                interval: TimeInterval(minutes: Double(data[start]))
            )
        }
    }
}
