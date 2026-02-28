extension EversenseE3 {
    class SetHighGlucoseRepeatIntervalDayPacket: BasePacket {
        typealias T = SetHighGlucoseRepeatIntervalResponse

        var responseType: UInt8 {
            PacketIds.writeSingleByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        let interval: TimeInterval
        init(interval: TimeInterval) {
            self.interval = interval
        }

        func getRequestData() -> Data {
            CommandOperations.writeSingleByteSerialFlashRegister(
                memoryAddress: FlashMemory.highGlucoseAlarmRepeatIntervalDay,
                data: Data([UInt8(interval.minutes)])
            )
        }

        func parseResponse(data _: Data) -> EversenseE3.SetHighGlucoseRepeatIntervalResponse {
            SetHighGlucoseRepeatIntervalResponse()
        }
    }
}
