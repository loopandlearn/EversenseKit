extension EversenseE3 {
    class GetCommunicationVersionResponse {
        let version: Double
        init(version: Double) {
            self.version = version
        }
    }

    class GetCommunicationVersionPacket: BasePacket {
        typealias T = GetCommunicationVersionResponse

        var responseType: UInt8 {
            PacketIds.readFourByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readFourByteSerialFlashRegister(memoryAddress: FlashMemory.communicationProtocolVersion)
        }

        func parseResponse(data: Data) -> EversenseE3.GetCommunicationVersionResponse {
            let versionStr = String(data: data.subdata(in: 3 ..< 7), encoding: .utf8) ?? ""
            return GetCommunicationVersionResponse(
                version: Double(versionStr) ?? 0
            )
        }
    }
}
