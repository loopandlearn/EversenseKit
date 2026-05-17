extension EversenseE3 {
    class GetSensorIdResponse {
        let sensorId: Data

        init(sensorId: Data) {
            self.sensorId = sensorId
        }
    }

    class GetSensorIdPacket: BasePacket {
        typealias T = GetSensorIdResponse

        var responseType: UInt8 {
            PacketIds.readFourByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readFourByteSerialFlashRegister(memoryAddress: FlashMemory.linkedSensorId)
        }

        func parseResponse(data: Data) -> GetSensorIdResponse {
            GetSensorIdResponse(
                sensorId: Data(data.subdata(in: start ..< start + 4))
            )
        }
    }
}
