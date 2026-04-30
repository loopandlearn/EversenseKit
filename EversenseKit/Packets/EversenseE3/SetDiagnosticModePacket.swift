extension EversenseE3 {
    class SetDiagnosticModeResponse {}

    class SetDiagnosticModePacket: BasePacket {
        typealias T = SetDiagnosticModeResponse

        var responseType: UInt8 {
            enabled ? PacketIds.enterDiagnosticModeResponseId.rawValue : PacketIds.exitDiagnosticModeResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        let enabled: Bool
        init(enabled: Bool) {
            self.enabled = enabled
        }

        func getRequestData() -> Data {
            var data = Data([
                enabled ? PacketIds.enterDiagnosticModeCommandId.rawValue : PacketIds.exitDiagnosticModeCommandId.rawValue
            ])

            let checksum = BinaryOperations.generateChecksumCRC16(data: data)
            data.append(BinaryOperations.dataFrom16Bits(value: checksum))

            return data
        }

        func parseResponse(data _: Data) -> SetDiagnosticModeResponse {
            SetDiagnosticModeResponse()
        }
    }
}
