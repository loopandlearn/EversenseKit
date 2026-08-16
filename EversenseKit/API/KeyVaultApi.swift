enum KeyVaultApi {
    private static let transmitterNo = "000000"
    private static let clientNo = 2
    private static let clientType = 128

    private static let logger = EversenseLogger(category: "KeyVaultApi")

    static func getFleetSecret(cgmManager: EversenseCGMManager, accessToken: String) async throws -> SecureKeyResponse {
        let message = [
            "transmitterNo=\(transmitterNo)",
            "clientNo=\(clientNo)"
        ].joined(separator: "&")

        guard let url = URL(string: "\(cgmManager.state.apiZone.keyVaultUrl)/GetTxFleetSecret?\(message)") else {
            logger.error("Could not create URL...")
            throw NSError(domain: "Could not create URL...", code: -1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]

        let (data, response) = try await URLSession.shared.data(for: request)
        logger
            .info(
                "Received response from KeyVault: \((response as? HTTPURLResponse)?.statusCode ?? -1) \(String(data: data, encoding: .utf8) ?? "No data")"
            )
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            logger.error("Got invalid response from KeyVault")
            throw NSError(domain: message, code: -1)
        }

        return try JSONDecoder().decode(SecureKeyResponse.self, from: data)
    }

    static func getFleetSecretV2(
        cgmManager: EversenseCGMManager,
        accessToken: String,
        serialNumber: String,
        nonce: String,
        flags: Bool,
        kpClientUniqueId: String
    ) async -> SecureKeyResponse? {
        let message = [
            "tx_flags=\(flags)",
            "txSerialNumber=\(serialNumber)",
            "nonce=\(nonce)",
            "clientNo=\(clientNo)",
            "clientType=\(clientType)",
            "kp_client_unique_id=\(kpClientUniqueId)"
        ].joined(separator: "&")

        guard let url = URL(string: "\(cgmManager.state.apiZone.keyVaultUrl)/GetTxCertificate?\(message)") else {
            logger.error("Could not create URL...")
            return nil
        }

        logger.debug("Sending request to: \(cgmManager.state.apiZone.keyVaultUrl)/GetTxCertificate?\(message)")
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                logger
                    .error(
                        "Got invalid response from KeyVault: \((response as? HTTPURLResponse)?.statusCode ?? -1) \(String(data: data, encoding: .utf8) ?? "No data")"
                    )
                return nil
            }

            logger.info("Fleet secret: \(String(data: data, encoding: .utf8) ?? "No data")")
            return try JSONDecoder().decode(SecureKeyResponse.self, from: data)
        } catch {
            logger.error("Failed to do request: \(error.localizedDescription)")
            return nil
        }
    }
}
