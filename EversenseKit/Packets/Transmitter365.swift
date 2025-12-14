import LoopKit

extension Eversense365 {
    static let fakeAppVersion = "8.0.4"
    static let logger = EversenseLogger(category: "TransmitterState365")
    static var sensorIdLength = 0x00

    static func readGlucoseData(
        peripheralManager: PeripheralManager,
        cgmManager: EversenseCGMManager,
        lastGlucoseTimestamp: Date
    ) async -> [NewGlucoseSample] {
        do {
            logger.debug("sending GetRecentGlucosePacket...")
            let mostRecentGlucose = await getRecentGlucose(peripheralManager: peripheralManager)

            logger.debug("sending GetGlucoseLogRangePacket...")
            let glucoseRange: GetLogRangeResponse = try await peripheralManager
                .write(GetLogRangePacket(communicationVersion: cgmManager.state.communicationProtocol, logType: LogTypes.Glucose))
            logger.info("Got Blood glucose range from: \(glucoseRange.rangeFrom) - \(glucoseRange.rangeTo)")

            guard glucoseRange.rangeFrom > 0 else {
                logger.warning("No glucose data available...")
                return []
            }

            let range = RangeCalculator.calculateGlucoseRange(
                rangeFrom: glucoseRange.rangeFrom,
                rangeTo: glucoseRange.rangeTo,
                lastGlucoseTimestamp: lastGlucoseTimestamp
            )

            let message =
                "GetLogValuePacket -  from: \(range.from), to: \(range.to), lastGlucoseTimestamp: \(lastGlucoseTimestamp)"
            logger.debug(message)
            let historyResponse: GetGlucoseLogValuesResponse = try await peripheralManager
                .write(GetGlucoseLogValuesPacket(from: range.from, to: range.to), timeout: .seconds(15))

            if let mostRecentGlucose = mostRecentGlucose,
               mostRecentGlucose.glucoseDatetime > (cgmManager.state.recentGlucoseDateTime ?? Date.distantPast)
            {
                cgmManager.state.recentGlucoseInMgDl = mostRecentGlucose.glucoseInMgDl
                cgmManager.state.recentGlucoseDateTime = mostRecentGlucose.glucoseDatetime
            } else if let recentGlucose = historyResponse.glucoseHistory.last,
                      recentGlucose.datetime > (cgmManager.state.recentGlucoseDateTime ?? Date.distantPast)
            {
                cgmManager.state.recentGlucoseInMgDl = recentGlucose.valueInMgDl
                cgmManager.state.recentGlucoseDateTime = recentGlucose.datetime
            }

            var samples = historyResponse.glucoseHistory.filter { $0.datetime > lastGlucoseTimestamp }.map {
                NewGlucoseSample(
                    cgmManager: cgmManager,
                    value: $0.valueInMgDl,
                    trend: $0.trend,
                    dateTime: $0.datetime
                )
            }

            if let mostRecentGlucose = mostRecentGlucose {
                samples.append(
                    NewGlucoseSample(
                        cgmManager: cgmManager,
                        value: mostRecentGlucose.glucoseInMgDl,
                        trend: mostRecentGlucose.trend,
                        dateTime: mostRecentGlucose.glucoseDatetime
                    )
                )
            }

            logger.info("[365] Glucose data read  - timestamp: \(Date.now), count: \(samples.count)")
            return samples
        } catch {
            logger.error("[365] Something went wrong during readGlucoseData: \(error)")
            return []
        }
    }

    private static func getRecentGlucose(peripheralManager: PeripheralManager) async -> GetGlucoseDataResponse? {
        do {
            let response: GetGlucoseDataResponse = try await peripheralManager.write(GetGlucoseDataPacket())
            guard response.glucoseInMgDl < 0x03E8 else {
                let message =
                    "Invalid Glucose data - value: \(response.glucoseInMgDl) mg/dl, timestamp: \(response.glucoseDatetime)"
                logger.warning(message)
                return nil
            }

            return response
        } catch {
            logger.error("Failed to fetch Glucose data - error: \(error.localizedDescription)")
            return nil
        }
    }

    static func fullSync(
        peripheralManager: PeripheralManager,
        cgmManager: EversenseCGMManager
    ) async {
        do {
            cgmManager.state.isSyncing = true
            cgmManager.notifyStateDidChange()

            // Do Ping
            logger.debug("Sending PING")
            let _: PingResponse = try await peripheralManager.write(PingPacket())

            // Get transmitter information
            logger.debug("Sending GetSensorInformationPacket")
            let sensorInformation: GetSensorInformationResponse = try await peripheralManager
                .write(GetSensorInformationPacket())

            cgmManager.state.mmaFeatures = sensorInformation.mmaFeatures
            cgmManager.state.batteryPercentage = sensorInformation.batteryLevel
            cgmManager.state.version = sensorInformation.version
            cgmManager.state.extVersion = sensorInformation.extVersion
            cgmManager.state.communicationProtocol = sensorInformation.communicationProtocolVersion
            sensorIdLength = sensorInformation.sensorIdLength

            let timeDifference = sensorInformation.transmitterDatetime.timeIntervalSince1970 - Date.nowWithTimezone()
                .timeIntervalSince1970
            if abs(timeDifference) >= TimeInterval.minutes(2) {
                logger.info("Updating transmitter datetime -> current date \(sensorInformation.transmitterDatetime)")
                let _: Eversense365.SetCurrentDateTimeResponse = try await peripheralManager
                    .write(Eversense365.SetCurrentDateTimePacket())
            }

            // Fetch signal strength
            logger.debug("Sending GetSignalStrenghtPacket")
            let signalStrength: GetSignalStrenghtResponse = try await peripheralManager.write(GetSignalStrenghtPacket())
            cgmManager.state.signalStrengthRaw = signalStrength.rawValue
            cgmManager.state.signalStrength = signalStrength.signalStrength

            logger.debug("Sending GetCalibrationInfoPacket")
            let calibrationInfo: GetCalibrationInfoResponse = try await peripheralManager.write(GetCalibrationInfoPacket())
            cgmManager.state.calibrationCount = UInt16(calibrationInfo.countCalibrations)
            cgmManager.state.calibrationReadiness = calibrationInfo.calibrationReadiness
            cgmManager.state.calibrationMode = calibrationInfo.calibrationMode
            cgmManager.state.calibrationPhase = calibrationInfo.currentPhase
            cgmManager.state.lastCalibration = calibrationInfo.lastCalibration
            cgmManager.state.nextCalibration = calibrationInfo.nextCalibration

            logger.debug("Sending SetAppVersionPacket")
            let _: SetAppVersionResponse = try await peripheralManager.write(SetAppVersionPacket(appVersion: fakeAppVersion))

            logger.debug("Sending GetPatientSettingsPacket")
            let patientSettings: GetPatientSettingsResponse = try await peripheralManager.write(GetPatientSettingsPacket())
            cgmManager.state.vibrateMode = patientSettings.vibrateMode
            cgmManager.state.isGlucoseHighAlarmEnabled = patientSettings.isGlucoseHighAlarmEnabled
            cgmManager.state.lowGlucoseAlarmInMgDl = patientSettings.lowGlucoseAlarmInMgDl
            cgmManager.state.highGlucoseAlarmInMgDl = patientSettings.highGlucoseAlarmInMgDl
            cgmManager.state.isPredictionLowEnabled = patientSettings.isPredictionLowEnabled
            cgmManager.state.isPredictionHighEnabled = patientSettings.isPredictionHighEnabled
            cgmManager.state.predictionFallingInterval = patientSettings.predictionFallingInterval
            cgmManager.state.predictionRisingInterval = patientSettings.predictionRisingInterval
            cgmManager.state.isFallingRateEnabled = patientSettings.isFallingRateEnabled
            cgmManager.state.isRisingRateEnabled = patientSettings.isRisingRateEnabled
            cgmManager.state.rateFallingThreshold = patientSettings.rateFallingThreshold
            cgmManager.state.rateRisingThreshold = patientSettings.rateRisingThreshold

            logger.debug("Sending GetActiveAlarmsPacket")
            let activeAlarms: GetActiveAlarmsResponse = try await peripheralManager.write(GetActiveAlarmsPacket())
            cgmManager.state.activeAlarms = activeAlarms.alarms

            logger.info("[365] Sync completed - timestamp: \(Date.now)")

        } catch {
            logger.error("[365] Something went wrong during full sync: \(error)")
        }

        cgmManager.state.isSyncing = false
        cgmManager.state.lastSynced = Date.now
        cgmManager.notifyStateDidChange()
    }

    static func writeTransmitterSettings(
        cgmManager: EversenseCGMManager,
        data: TransmitterSettings
    ) async {
        do {
            logger.debug("sending SetVibrateModePacket...")
            let _: SetVibrateModeResponse = try await cgmManager.bluetoothManager
                .write(SetVibrateModePacket(enabled: data.vibrationMode))

            logger.debug("sending SetHighGlucoseAlarmEnabledPacket...")
            let _: SetHighGlucoseAlarmEnabledResponse = try await cgmManager.bluetoothManager
                .write(SetHighGlucoseAlarmEnabledPacket(enabled: data.enableGlucoseHighAlerts))

            logger.debug("sending SetHighGlucoseAlarmPacket...")
            let _: SetHighGlucoseAlarmResponse = try await cgmManager.bluetoothManager
                .write(SetHighGlucoseAlarmPacket(value: data.glucoseHighInMgDl))

            logger.debug("sending SetLowGlucoseAlarmPacket...")
            let _: SetLowGlucoseAlarmResponse = try await cgmManager.bluetoothManager
                .write(SetLowGlucoseAlarmPacket(value: data.glucoseLowInMgDl))

            logger.debug("sending SetRateRisingEnabledPacket...")
            let _: SetRateRisingEnabledResponse = try await cgmManager.bluetoothManager
                .write(SetRateRisingEnabledPacket(enabled: data.isRisingRateEnabled))

            logger.debug("sending SetRateRisingThresholdPacket...")
            let _: SetRateRisingThresholdResponse = try await cgmManager.bluetoothManager
                .write(SetRateRisingThresholdPacket(value: data.rateRisingThreshold))

            logger.debug("sending SetRateFallingEnabledPacket...")
            let _: SetRateFallingEnabledResponse = try await cgmManager.bluetoothManager
                .write(SetRateFallingEnabledPacket(enabled: data.isFallingRateEnabled))

            logger.debug("sending SetRateFallingThresholdPacket...")
            let _: SetRateFallingThresholdResponse = try await cgmManager.bluetoothManager
                .write(SetRateFallingThresholdPacket(value: data.rateFallingThreshold))

            logger.info("[365] Transmitter settings have been written - timestamp: \(Date.now)")
        } catch {
            logger.error("[365] Something went wrong setting transmitter settings: \(error)")
        }
    }

    static func updateSignalStrength(cgmManager: EversenseCGMManager) async {
        do {
            logger.debug("sending GetSignalStrenghtResponse...")
            let signalStrength: GetSignalStrenghtResponse = try await cgmManager.bluetoothManager.write(GetSignalStrenghtPacket())
            cgmManager.state.signalStrengthRaw = signalStrength.rawValue
            cgmManager.state.signalStrength = signalStrength.signalStrength

            cgmManager.notifyStateDidChange()
        } catch {
            logger.error("Failed to update signal strength - error: \(error)")
        }
    }

    static func calibrateSensors(cgmManager: EversenseCGMManager, glucoseInMgDl: UInt16, timestamp: Date) async throws {
        do {
            logger.info("Sending SetBloodGlucosePointPacket - glucose: \(glucoseInMgDl)mg/dl, timestamp: \(timestamp)")

            let _: SetBloodGlucosePointResponse = try await cgmManager.bluetoothManager
                .write(SetBloodGlucosePointPacket(glucoseInMgDl: glucoseInMgDl, timestamp: timestamp))

            logger.info("[365] Calibation has been send - timestamp: \(Date.now)")
        } catch {
            logger.error("[365] Something went wrong during calibration: \(error)")
            throw error
        }
    }

    static func handleError(data: Data) {
        // TODO: Emit error
        logger.warning("Received error from transmitter - data: \(data.hexString())")
    }
}
