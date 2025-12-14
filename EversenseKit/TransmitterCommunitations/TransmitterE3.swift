import LoopKit

extension EversenseE3 {
    static let fakeAppVersion = "8.0.1"
    static let logger = EversenseLogger(category: "TransmitterStateE3")

    static func readGlucoseData(
        peripheralManager: PeripheralManager,
        cgmManager: EversenseCGMManager,
        lastGlucoseTimestamp: Date
    ) async -> [NewGlucoseSample] {
        do {
            let glucoseData: GetGlucoseDataResponse = try await peripheralManager.write(GetGlucoseDataPacket())
            let recentGlucoseValue: GetRecentGlucoseValueResponse = try await peripheralManager
                .write(GetRecentGlucoseValuePacket())
            let recentGlucoseDate: GetRecentGlucoseDateResponse = try await peripheralManager.write(GetRecentGlucoseDatePacket())
            let recentGlucoseTime: GetRecentGlucoseTimeResponse = try await peripheralManager.write(GetRecentGlucoseTimePacket())

            let dateTime = Date.fromComponents(
                date: recentGlucoseDate.date,
                time: recentGlucoseTime.time
            )

            guard recentGlucoseValue.valueInMgDl < 0x03E8 else { // 1000 mg/dl
                let message =
                    "Received invalid Glucose data - value: \(recentGlucoseValue.valueInMgDl) mg/dl, timestamp sample: \(dateTime)"
                logger.error(message)
                return []
            }

            guard dateTime > lastGlucoseTimestamp else {
                let message =
                    "Received old glucose data - value: \(recentGlucoseValue.valueInMgDl) mg/dl, timestamp sample: \(dateTime)"
                logger.warning(message)
                return []
            }

            cgmManager.state.recentGlucoseInMgDl = recentGlucoseValue.valueInMgDl
            cgmManager.state.recentGlucoseDateTime = dateTime

            // TODO: Read history

            logger.info("[E3] Glucose data read  - timestamp: \(Date.now)")

            return [
                NewGlucoseSample(
                    cgmManager: cgmManager,
                    value: recentGlucoseValue.valueInMgDl,
                    trend: glucoseData.trend,
                    dateTime: dateTime
                )
            ]
        } catch {
            logger.error("[E3] Something went wrong during readGlucoseData: \(error)")
            return []
        }
    }

    static func fullSync(
        peripheralManager: PeripheralManager,
        cgmManager: EversenseCGMManager
    ) async {
        do {
            cgmManager.state.isSyncing = true
            cgmManager.notifyStateDidChange()

            let currentDateTime: GetCurrentDateTimeResponse = try await peripheralManager
                .write(GetCurrentDateTimePacket())
            let timeDifference = currentDateTime.datetime.timeIntervalSince1970 - Date.nowWithTimezone().timeIntervalSince1970
            if abs(timeDifference) >= TimeInterval.minutes(2) {
                logger.info("Updating transmitter datetime -> current date \(currentDateTime.datetime)")
                let _: SetCurrentDateTimeResponse = try await peripheralManager
                    .write(SetCurrentDateTimePacket())
            }

            // Get MMA Features
            let mmaResponse: GetMmaFeaturesResponse = try await peripheralManager
                .write(GetMmaFeaturesPacket())
            cgmManager.state.mmaFeatures = mmaResponse.value

            // Get battery percentage
            let batteryPercentage: GetBatteryPercentageResponse = try await peripheralManager
                .write(GetBatteryPercentagePacket())
            cgmManager.state.batteryPercentage = batteryPercentage.value.percentage()

            // Do Ping
            let _: PingResponse = try await peripheralManager.write(PingPacket())

            // Get Transmitter version & extended Version
            let versionResponse: GetVersionResponse = try await peripheralManager
                .write(GetVersionPacket())
            let versionExtendedResponse: GetVersionExtendedResponse = try await peripheralManager
                .write(GetVersionExtendedPacket())
            cgmManager.state.version = versionResponse.version
            cgmManager.state.extVersion = versionExtendedResponse.extVersion

            // Get last calibration datetime
            let lastCalibrationDate: GetLastCalibrationDateResponse = try await peripheralManager
                .write(GetLastCalibrationDatePacket())
            let lastCalibrationTime: GetLastCalibrationTimeResponse = try await peripheralManager
                .write(GetLastCalibrationTimePacket())
            let lastCalibrationDatetime = Date.fromComponents(
                date: lastCalibrationDate.date,
                time: lastCalibrationTime.time
            )
            cgmManager.state.lastCalibration = lastCalibrationDatetime

            // Get current calibration phase
            let calibrationMode: CalibrationMode
            do {
                let isOneCalPhase: GetIsOneCalPhaseResponse = try await peripheralManager
                    .write(GetIsOneCalPhasePacket())

                calibrationMode = isOneCalPhase.value ? .DailySingle : .DailyDual
                cgmManager.state.calibrationMode = calibrationMode
            } catch {
                calibrationMode = .Default
                cgmManager.state.calibrationMode = .Default
            }

            let calibrationCount: GetCompletedCalibrationsCountResponse = try await peripheralManager
                .write(GetCompletedCalibrationsCountPacket())
            let calibrationPhase: GetCurrentCalibrationPhaseResponse = try await peripheralManager
                .write(GetCurrentCalibrationPhasePacket())
            cgmManager.state.calibrationCount = calibrationCount.value
            cgmManager.state.calibrationPhase = calibrationPhase.phase
            cgmManager.state.nextCalibration = lastCalibrationDatetime.addingTimeInterval(calibrationMode.toPeriod())

            // Get BLE disconnect alarm -> possible we get no reply, this feature might not be supported
            do {
                let bleDisconnectAlarm: GetDelayBLEDisconnectAlarmResponse = try await peripheralManager
                    .write(GetDelayBLEDisconnectAlarmPacket())
                cgmManager.state.isDelayBLEDisconnectionAlarmSupported = true
                cgmManager.state.delayBLEDisconnectionAlarm = bleDisconnectAlarm.value
            } catch {
                cgmManager.state.isDelayBLEDisconnectionAlarmSupported = false
                cgmManager.state.delayBLEDisconnectionAlarm = .seconds(180)
            }

            let vibrateMode: GetVibrateModeResponse = try await peripheralManager
                .write(GetVibrateModePacket())
            cgmManager.state.vibrateMode = vibrateMode.value

            // Write the fake app version
            if let appVersion = SetAppVersionPacket.parseAppVersion(version: fakeAppVersion) {
                let _: SetAppVersionResponse = try await peripheralManager
                    .write(SetAppVersionPacket(appVersion: appVersion))
            }

            // Get glucose alarms & status
            let glucoseAlarmsStatus: GetGlucoseAlertsAndStatusPacketResonse = try await peripheralManager
                .write(GetGlucoseAlertsAndStatusPacket())
            cgmManager.state.alarms = glucoseAlarmsStatus.alarms

            // Get glucose alarm enabled & thresholds
            let isGlucoseAlarmEnabled: GetHighGlucoseAlarmEnabledResponse = try await peripheralManager
                .write(GetHighGlucoseAlarmEnabledPacket())
            let lowGlucoseAlarm: GetLowGlucoseAlarmResponse = try await peripheralManager
                .write(GetLowGlucoseAlarmPacket())
            let highGlucoseAlarm: GetHighGlucoseAlarmResponse = try await peripheralManager
                .write(GetHighGlucoseAlarmPacket())
            cgmManager.state.isGlucoseHighAlarmEnabled = isGlucoseAlarmEnabled.value
            cgmManager.state.lowGlucoseAlarmInMgDl = lowGlucoseAlarm.valueInMgDl
            cgmManager.state.highGlucoseAlarmInMgDl = highGlucoseAlarm.valueInMgDl

            // Get predictive values
            let isPredictionLowEnabled: GetPredictiveLowAlertsResponse = try await peripheralManager
                .write(GetPredictiveLowAlertsPacket())
            let isPredictionHighEnabled: GetPredictiveHighAlertsResponse = try await peripheralManager
                .write(GetPredictiveHighAlertsPacket())
            let predictionFallingInterval: GetPredictiveFallingTimeIntervalResponse = try await peripheralManager
                .write(GetPredictiveFallingTimeIntervalPacket())
            let predictionRisingInterval: GetPredictiveRisingTimeIntervalResponse = try await peripheralManager
                .write(GetPredictiveRisingTimeIntervalPacket())
            cgmManager.state.isPredictionLowEnabled = isPredictionLowEnabled.value
            cgmManager.state.isPredictionHighEnabled = isPredictionHighEnabled.value
            cgmManager.state.predictionFallingInterval = predictionFallingInterval.value
            cgmManager.state.predictionRisingInterval = predictionRisingInterval.value

            // Get rate values
            let isFallingRateEnabled: GetRateFallingAlertResponse = try await peripheralManager
                .write(GetRateFallingAlertPacket())
            let isRisingRateEnabled: GetRateRisingAlertResponse = try await peripheralManager
                .write(GetRateRisingAlertPacket())
            let rateFallingThreshold: GetRateFallingThresholdResponse = try await peripheralManager
                .write(GetRateFallingThresholdPacket())
            let rateRisingThreshold: GetRateRisingThresholdResponse = try await peripheralManager
                .write(GetRateRisingThresholdPacket())
            cgmManager.state.isFallingRateEnabled = isFallingRateEnabled.value
            cgmManager.state.isRisingRateEnabled = isRisingRateEnabled.value
            cgmManager.state.rateFallingThreshold = rateFallingThreshold.value
            cgmManager.state.rateRisingThreshold = rateRisingThreshold.value

            // Get signal strength
            let rawSignalStrength: GetSignalStrengthRawResponse = try await peripheralManager
                .write(GetSignalStrengthRawPacket())
            cgmManager.state.signalStrength = rawSignalStrength.value
            cgmManager.state.signalStrengthRaw = rawSignalStrength.rawValue

            // TODO: Get active alarms

            logger.info("[E3] Sync completed - timestamp: \(Date.now)")

        } catch {
            logger.error("[E3] Something went wrong during full sync: \(error)")
        }

        cgmManager.state.isSyncing = false
        cgmManager.state.lastSynced = Date.now
        cgmManager.notifyStateDidChange()
    }

    static func updateSignalStrength(cgmManager: EversenseCGMManager) async {
        do {
            let rawSignalStrength: GetSignalStrengthRawResponse = try await cgmManager.bluetoothManager
                .write(GetSignalStrengthRawPacket())
            cgmManager.state.signalStrength = rawSignalStrength.value
            cgmManager.state.signalStrengthRaw = rawSignalStrength.rawValue

            cgmManager.notifyStateDidChange()
        } catch {
            logger.error("Failed to update signal strength - error: \(error)")
        }
    }

    static func writeTransmitterSettings(
        cgmManager: EversenseCGMManager,
        data: TransmitterSettings
    ) async {
        do {
            let _: SetVibrateModeResponse = try await cgmManager.bluetoothManager
                .write(SetVibrateModePacket(enabled: data.vibrationMode))

            let _: SetHighGlucoseAlarmEnabledResponse = try await cgmManager.bluetoothManager
                .write(SetHighGlucoseAlarmEnabledPacket(enabled: data.enableGlucoseHighAlerts))
            let _: SetHighGlucoseAlarmResponse = try await cgmManager.bluetoothManager
                .write(SetHighGlucoseAlarmPacket(value: data.glucoseHighInMgDl))
            let _: SetLowGlucoseAlarmResponse = try await cgmManager.bluetoothManager
                .write(SetLowGlucoseAlarmPacket(value: data.glucoseLowInMgDl))

            let _: SetRateRisingEnabledResponse = try await cgmManager.bluetoothManager
                .write(SetRateRisingEnabledPacket(enabled: data.isRisingRateEnabled))
            let _: SetRateRisingThresholdResponse = try await cgmManager.bluetoothManager
                .write(SetRateRisingThresholdPacket(value: data.rateRisingThreshold))
            let _: SetRateFallingEnabledResponse = try await cgmManager.bluetoothManager
                .write(SetRateFallingEnabledPacket(enabled: data.isFallingRateEnabled))
            let _: SetRateFallingThresholdResponse = try await cgmManager.bluetoothManager
                .write(SetRateFallingThresholdPacket(value: data.rateFallingThreshold))

            logger.info("[E3] Transmitter settings have been written - timestamp: \(Date.now)")
        } catch {
            logger.error("[E3] Something went wrong during setting transmitter settings: \(error)")
        }
    }

    static func handleError(data: Data) {
        guard data.count >= 4 else {
            logger.error("Invalid error response length - length: \(data.count), data: \(data.hexString())")
            return
        }

        let code = (UInt16(data[3]) << 8) | UInt16(data[2])
        guard let error = CommandError(rawValue: code) else {
            logger.error("Received unknown error - code: \(code), data: \(data.hexString())")
            return
        }

        // TODO: Emit error
        logger.warning("Received error from transmitter - error: \(error), data: \(data.hexString())")
    }

    static func calibrateSensors(cgmManager: EversenseCGMManager, glucoseInMgDl: UInt16, timestamp: Date) async throws {
        do {
            logger.info("Sending SetBloodGlucosePointPacket - glucose: \(glucoseInMgDl)mg/dl, timestamp: \(timestamp)")

            let _: SetBloodGlucosePointResponse = try await cgmManager.bluetoothManager
                .write(SetBloodGlucosePointPacket(glucoseInMgDl: glucoseInMgDl, timestamp: timestamp))

            logger.info("[E3] Calibation has been send - timestamp: \(Date.now)")
        } catch {
            logger.error("[E3] Something went wrong during calibration: \(error)")
            throw error
        }
    }
}
