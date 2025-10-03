extension Eversense365 {
    class AuthWhoAmIResponse {
        let nonce: Data
        let serialNumber: Data
        let flags: Bool

        init(nonce: Data, serialNumber: Data, flags: Bool) {
            self.nonce = nonce
            self.serialNumber = serialNumber
            self.flags = flags
        }
    }

    class AuthWhoAmIPacket: BasePacket {
        typealias T = AuthWhoAmIResponse

        var responseType: UInt8 {
            PacketIds.AuthenticateV2ResponseId.rawValue
        }

        var responseId: UInt8? {
            AuthTypes.AuthenticateV2WhoAmI.rawValue
        }

        let secret: Data
        init(secret: Data) {
            self.secret = secret
        }

        func getRequestData() -> Data {
            var data = Data([PacketIds.AuthenticateV2CommandId.rawValue, AuthTypes.AuthenticateV2WhoAmI.rawValue])
            data.append(secret)

            return data
        }

        /// Message parsed:
        /// 0B 01 -> CmdType & CmdId
        /// 33 30 36 33 36 36 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 -> Serial number
        /// 46 F7 77 9A E5 42 66 FF -> Nonce
        /// 01 00 -> Flags??
        func parseResponse(data: Data) -> AuthWhoAmIResponse {
            let serialNumberData = data.subdata(in: 2 ..< 34)
            let nonce = data.subdata(in: 34 ..< 42)

            return AuthWhoAmIResponse(
                nonce: nonce,
                serialNumber: serialNumberData,
                flags: ((UInt16(data[43]) << 8) | UInt16(data[42]) & 0x0F) == 0
            )
        }
    }
}
