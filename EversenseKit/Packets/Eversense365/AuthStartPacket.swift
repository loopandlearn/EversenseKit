extension Eversense365 {
    class AuthStartResponse {
        let sessionPublicKey: Data

        init(sessionPublicKey: Data) {
            self.sessionPublicKey = sessionPublicKey
        }
    }

    class AuthStartPacket: BasePacket {
        typealias T = AuthStartResponse

        var responseType: UInt8 {
            PacketIds.AuthenticateV2ResponseId.rawValue
        }

        var responseId: UInt8? {
            AuthTypes.AuthenticateV2Start.rawValue
        }

        let secret: Data
        init(
            clientId: Data,
            ephemPublicKey: Data,
            salt: Data,
            digitalSignature: Data
        ) {
            var startSecret = Data([128, 0])
            startSecret.append(clientId)
            startSecret.append(ephemPublicKey.subdata(in: 27 ..< ephemPublicKey.count))
            startSecret.append(salt)
            startSecret.append(digitalSignature)

            secret = startSecret
        }

        func getRequestData() -> Data {
            var data = Data([PacketIds.AuthenticateV2CommandId.rawValue, AuthTypes.AuthenticateV2Start.rawValue])
            data.append(secret)

            return data
        }

        /// Message parsed:
        /// 0B 03 -> CmdType & CmdId
        /// DC46BEBE9096AA44E6BB42766B23C22886164C1BFBE55126A3284A98A1864EF0E09D63B705C4BE5D2E1AE1B07DCF2F72DC576DD76BB5DD0D70F2C6AA68134EE -> shared public key
        /// BAA63C88119A80D3E94B534E0DCF9C2EBC1DE44592B690BD2C00D4214B4CEA38D8804DFAB9902A7CD8B9DD3DC249204B12C36E707A2B97510E9250D03FA1E4FFD -> ECDSA Signature
        func parseResponse(data: Data) -> AuthStartResponse {
            if data.count <= 7 {
                return AuthStartResponse(
                    sessionPublicKey: data
                )
            }

            return AuthStartResponse(
                sessionPublicKey: data.subdata(in: 2 ..< 66)
            )
        }
    }
}
