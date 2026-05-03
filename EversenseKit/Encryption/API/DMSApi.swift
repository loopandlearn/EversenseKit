import LoopKit

enum DMSApi {
    private static let uploadBaseUrl = "https://usmobileappmsprod.eversensedms.com/"
    private static let careBaseUrl = "https://usapialpha.eversensedms.com/"

    private static let logger = EversenseLogger(category: "DMSApi")

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "GMT")!
        return formatter
    }()

    static func uploadGlucoseReadings(cgmManager: EversenseCGMManager, readings: [CGMReading], sensorId: Data) async -> Bool {
        guard let url = URL(string: "\(uploadBaseUrl)api/v1.0/DiagnosticLog/PostEssentialLogs") else {
            logger.error("Could not create URL...")
            return false
        }

        guard let lastSync = cgmManager.state.lastSynced else {
            logger.error("lastSynced is nil")
            return false
        }

        guard let transmitterId = cgmManager.state.transmitterId else {
            logger.error("transmitterId is nil")
            return false
        }

        guard let token = await getAccessToken(cgmManager: cgmManager) else {
            return false
        }

        do {
            let syncDate = dateFormatter.string(from: lastSync)
            let sensorId = Data(sensorId.subdata(in: 0 ..< 8).reversed()).hexString()
            let message = readings.map { reading in
                UploadGlucoseReadingRequest(
                    SensorId: sensorId,
                    TransmitterId: transmitterId,
                    Timestamp: syncDate,
                    CurrentGlucoseValue: Int(reading.glucoseInMgDl),
                    CurrentGlucoseDateTime: dateFormatter.string(from: reading.datetime),
                    FWVersion: cgmManager.state.version ?? "",
                    EssentialLog: ""
                )
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(message)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode < 400 else {
                let message =
                    "Got invalid response from PostEssentialLogs: \((response as? HTTPURLResponse)?.statusCode ?? -1) \(String(data: data, encoding: .utf8) ?? "No data")"

                logger.error(message)
                return false
            }

            logger
                .debug(
                    "PostEssentialLogs success! httpCode: \((response as? HTTPURLResponse)?.statusCode ?? -1), response: \(String(data: data, encoding: .utf8) ?? "EMPTY")"
                )
            return true
        } catch {
            logger.error("Failed to upload readings: \(error.localizedDescription)")
            return false
        }
    }

    static func uploadCurrentValues(cgmManager: EversenseCGMManager, reading: CGMReading) async -> Bool {
        guard let url = URL(string: "\(careBaseUrl)api/care/PutCurrentValues") else {
            logger.error("Could not create URL...")
            return false
        }

        guard let token = await getAccessToken(cgmManager: cgmManager) else {
            return false
        }

        do {
            let message = UploadCurrentGlucoseRequest(
                CurrentGlucose: Int(reading.glucoseInMgDl),
                CGTime: dateFormatter.string(from: reading.datetime),
                GlucoseTrend: mapTrend(reading.trend),
                SignalStrength: Int(cgmManager.state.signalStrength.rawValue),
                BatteryStrength: cgmManager.state.batteryPercentage,
                IsTransmitterConnected: true
            )

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(message)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode < 400 else {
                let message =
                    "Got invalid response from PutCurrentValues: \((response as? HTTPURLResponse)?.statusCode ?? -1) \(String(data: data, encoding: .utf8) ?? "No data")"

                logger.error(message)
                return false
            }

            logger
                .debug(
                    "PutCurrentValues success! httpCode: \((response as? HTTPURLResponse)?.statusCode ?? -1), response: \(String(data: data, encoding: .utf8) ?? "EMPTY")"
                )
            return true
        } catch {
            logger.error("Failed to upload readings: \(error.localizedDescription)")
            return false
        }
    }

    static func uploadDeviceEvents(cgmManager: EversenseCGMManager, readings: [CGMReading], sensorId: Data) async -> Bool {
        guard let url = URL(string: "\(careBaseUrl)api/care/PutDeviceEvents") else {
            logger.error("Could not create URL...")
            return false
        }

        guard let transmitterId = cgmManager.state.transmitterId else {
            logger.error("transmitterId is nil")
            return false
        }

        guard let token = await getAccessToken(cgmManager: cgmManager) else {
            return false
        }

        do {
            let message = UploadDeviceEventRequest(
                deviceType: "SMSIMeter",
                deviceName: "Senseonics Transmitter",
                deviceID: transmitterId,
                offsetBytes: buildOffsetBytes(),
                sgBytes: buildSgBytes(readings: readings, sensorId: sensorId),
                mgBytes: buildEmptyMgBytes(),
                patientBytes: buildEmptyPatientBytes(),
                alertBytes: buildAlertBytes(sensorId: sensorId),
                algorithmVersion: "10"
            )

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(message)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode < 400 else {
                let message =
                    "Got invalid response from PutDeviceEvents: \((response as? HTTPURLResponse)?.statusCode ?? -1) \(String(data: data, encoding: .utf8) ?? "No data")"

                logger.error(message)
                return false
            }

            logger
                .debug(
                    "PutDeviceEvents success! httpCode: \((response as? HTTPURLResponse)?.statusCode ?? -1), response: \(String(data: data, encoding: .utf8) ?? "EMPTY")"
                )
            return true
        } catch {
            logger.error("Failed to upload readings: \(error.localizedDescription)")
            return false
        }
    }

    private static func getAccessToken(cgmManager: EversenseCGMManager) async -> String? {
        let accessToken = cgmManager.state.accessToken
        let expiration = cgmManager.state.accessTokenExpiration

        if let accessToken, let expiration, expiration.timeIntervalSinceNow > 0 {
            return accessToken
        }

        guard let username = cgmManager.state.username, let password = cgmManager.state.password else {
            logger.error("User not logged in...")
            return nil
        }

        do {
            let response = try await AuthenticationApi.login(username: username, password: password)
            cgmManager.state.accessToken = response.accessToken
            cgmManager.state.accessTokenExpiration = Date.now.addingTimeInterval(.seconds(Double(response.expiresIn)))
            cgmManager.notifyStateDidChange()

            return response.accessToken
        } catch {
            logger.error("Failed to re-authenticate: \(error.localizedDescription)")
            return nil
        }
    }

    private static func mapTrend(_ trend: GlucoseTrend?) -> Int {
        guard let trend else {
            return 0
        }

        // STALE=0, FALLING_FAST=1, FALLING=2, FLAT=3, RISING=4, RISING_FAST=5
        switch trend {
        case .downDown,
             .downDownDown:
            return 1
        case .down:
            return 2
        case .flat:
            return 3
        case .up:
            return 4
        case .upUp,
             .upUpUp:
            return 5
        }
    }

    private static func buildOffsetBytes() -> String {
        let tzOffsetSec = TimeZone.current.secondsFromGMT()
        return Int64(tzOffsetSec)
            .toData(length: 3)
            .base64EncodedString()
    }

    private static func buildEmptyPatientBytes() -> String {
        // Header: 9E 01 00 + count(2 bytes LE)  → 0 events
        let data = Data([0x9E, 0x01, 0x00, 0x00, 0x00])
        return data.base64EncodedString()
    }

    private static func buildEmptyMgBytes() -> String {
        // Header: 98 01 00 + count(2 bytes LE) + 00  → 0 records
        let data = Data([0x98, 0x01, 0x00, 0x00, 0x00, 0x00])
        return data.base64EncodedString()
    }

    private static func buildAlertBytes(sensorId: Data) -> String {
        // Header: 93 01 00 + count(2 bytes LE) + sensorIdBytes + 00  → 0 alerts
        var data = Data([0x93, 0x01, 0x00, 0x00, 0x00])
        data.append(sensorId)
        data.append(0x00)

        return data.base64EncodedString()
    }

    private static func buildSgBytes(readings: [CGMReading], sensorId: Data) -> String {
        // Header: 8C 00 01 00 00 + count (3 bytes LE)
        var data = Data([0x8C, 0x00, 0x01, 0x00, 0x00])
        data.append(Int64(readings.count).toData(length: 3))

        let zeroInt16 = Int64(0).toData(length: 2)
        for (idx, r) in readings.enumerated() {
            data.append(Int64(idx + 1).toData(length: 3)) // record number (1-based)
            data.append(calcDateBytes(date: r.datetime)) // date
            data.append(calcTimeBytes(date: r.datetime)) // time
            data.append(Int64(r.glucoseInMgDl).toData(length: 2)) // glucose
            data.append(0x00) // padding
            data.append(sensorId) // sensor ID

            // RAW_DATA_INDEX 1, 2, 3, 7, 8 (no raw ADC data available)
            for _ in 0 ..< 5 {
                data.append(zeroInt16)
            }

            // Accel values (2 bytes)
            data.append(zeroInt16)

            // AccelTemp (1 byte)
            data.append(0x00)

            // RAW_DATA_INDEX 4, 5, 6
            for _ in 0 ..< 3 {
                data.append(zeroInt16)
            }
        }

        return data.base64EncodedString()
    }

    private static func calcDateBytes(date: Date) -> Data {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "GMT")!
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date) // 1-12
        let day = cal.component(.day, from: date)
        var b1 = (year - 2000) << 1
        if month > 7 { b1 += 1 }
        let b0 = ((month & 7) << 5) | day
        return Data([UInt8(truncatingIfNeeded: b0), UInt8(truncatingIfNeeded: b1)])
    }

    private static func calcTimeBytes(date: Date) -> Data {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "GMT")!
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let second = cal.component(.second, from: date)
        let b0 = ((minute & 7) << 5) | (second / 2)
        let b1 = (hour << 3) | ((minute & 56) >> 3)
        return Data([UInt8(truncatingIfNeeded: b0), UInt8(truncatingIfNeeded: b1)])
    }
}
