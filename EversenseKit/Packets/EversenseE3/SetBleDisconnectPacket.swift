extension EversenseE3 {
    class SetBleDisconnectResponse {}

    class SetBleDisconnectPacket: BasePacket {
        typealias T = SetBleDisconnectResponse

        var responseType: UInt8 {
            PacketIds.writeTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        let interval: TimeInterval
        init(interval: TimeInterval) {
            self.interval = interval
        }

        func getRequestData() -> Data {
            CommandOperations.writeTwoByteSerialFlashRegister(
                memoryAddress: FlashMemory.bleDisconnect,
                data: BinaryOperations.dataFrom16Bits(value: UInt16(interval))
            )
        }

        func parseResponse(data _: Data) -> EversenseE3.SetBleDisconnectResponse {
            SetBleDisconnectResponse()
        }
    }
}
