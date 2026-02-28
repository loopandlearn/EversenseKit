extension EversenseE3 {
    class GetBleDisconnectResponse {
        let interval: TimeInterval

        init(interval: TimeInterval) {
            self.interval = interval
        }
    }

    class GetBleDisconnectPacket: BasePacket {
        typealias T = GetBleDisconnectResponse

        var responseType: UInt8 {
            PacketIds.readTwoByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readTwoByteSerialFlashRegister(memoryAddress: FlashMemory.bleDisconnect)
        }

        func parseResponse(data: Data) -> EversenseE3.GetBleDisconnectResponse {
            let value = UInt16(data[start]) | UInt16(data[start + 1]) << 8

            return GetBleDisconnectResponse(
                interval: TimeInterval(Double(value))
            )
        }
    }
}
