extension EversenseE3 {
    class SetLowGlucoseRepeatIntervalResponse {}

    class SetLowGlucoseRepeatIntervalDayPacket: BasePacket {
        typealias T = SetLowGlucoseRepeatIntervalResponse

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
                memoryAddress: FlashMemory.lowGlucoseAlarmRepeatIntervalDay,
                data: Data([UInt8(interval.minutes)])
            )
        }

        func parseResponse(data _: Data) -> EversenseE3.SetLowGlucoseRepeatIntervalResponse {
            SetLowGlucoseRepeatIntervalResponse()
        }
    }
}
