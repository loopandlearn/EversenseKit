extension Eversense365 {
    class SetDiagnosticModeResponse {}

    class SetDiagnosticModePacket: BasePacket {
        typealias T = SetDiagnosticModeResponse

        var responseType: UInt8 {
            PacketIds.OperationResponseId.rawValue
        }

        var responseId: UInt8? {
            enabled ? OperationIds.enterDiagnosticMode.rawValue : OperationIds.exitDiagnosticMode.rawValue
        }

        let enabled: Bool
        init(enabled: Bool) {
            self.enabled = enabled
        }

        func getRequestData() -> Data {
            let data = Data([PacketIds.OperationCommandId.rawValue, responseId ?? 0])
            return CryptoUtil.shared.encrypt(data: data)
        }

        func parseResponse(data _: Data) -> SetDiagnosticModeResponse {
            SetDiagnosticModeResponse()
        }
    }
}
