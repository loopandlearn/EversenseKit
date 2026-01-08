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
            let mostRecentGlucose = await getRecentGlucose(peripheralManager: peripheralManager)

            logger.debug("Sending GetLogRangePacket...")
            let glucoseRange: GetLogRangeResponse = try await peripheralManager.write(GetLogRangePacket(type: .bloodGlucose))
            let range = RangeCalculator.calculateGlucoseRange(
                rangeFrom: glucoseRange.rangeFrom,
                rangeTo: glucoseRange.rangeTo,
                lastGlucoseTimestamp: lastGlucoseTimestamp
            )

            let message =
                "GetLogValuePacket -  from: \(range.from), to: \(range.to), lastGlucoseTimestamp: \(lastGlucoseTimestamp)"
            logger.debug(message)

            var glucoseHistory: [GetGlucoseLogResponse] = []
            for index in range.from ... range.to {
                let pageResponse: GetGlucoseLogResponse = try await peripheralManager.write(GetGlucoseLogPacket(index: index))

                logger.debug("Datetime: \(pageResponse.datetime), Glucose: \(pageResponse.glucoseInMgDl) mg/dl")
                glucoseHistory.append(pageResponse)
            }

            if let mostRecentGlucose = mostRecentGlucose,
               mostRecentGlucose.glucoseDatetime > (cgmManager.state.recentGlucoseDateTime ?? Date.distantPast)
            {
                cgmManager.state.recentGlucoseInMgDl = mostRecentGlucose.glucoseInMgDl
                cgmManager.state.recentGlucoseDateTime = mostRecentGlucose.glucoseDatetime
            } else if let recentGlucose = glucoseHistory.last,
                      recentGlucose.datetime > (cgmManager.state.recentGlucoseDateTime ?? Date.distantPast)
            {
                cgmManager.state.recentGlucoseInMgDl = recentGlucose.glucoseInMgDl
                cgmManager.state.recentGlucoseDateTime = recentGlucose.datetime
            }

            var samples = glucoseHistory.filter { $0.datetime > lastGlucoseTimestamp }.map {
                NewGlucoseSample(
                    cgmManager: cgmManager,
                    value: $0.glucoseInMgDl,
                    trend: nil,
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

            logger.info("[E3] Glucose data read  - timestamp: \(Date.now), count: \(samples.count)")
            return samples
        } catch {
            logger.error("[E3] Something went wrong during readGlucoseData: \(error)")
            return []
        }
    }

    private static func getRecentGlucose(peripheralManager: PeripheralManager) async -> Eversense365.GetGlucoseDataResponse? {
        do {
            logger.debug("Sending GetCurrentGlucosePacket...")
            let glucoseData: GetCurrentGlucoseResponse = try await peripheralManager.write(GetCurrentGlucosePacket())

            guard glucoseData.glucoseInMgDl < 0x03E8 else { // 1000 mg/dl
                let message =
                    "Received invalid Glucose data - value: \(glucoseData.glucoseInMgDl) mg/dl, timestamp sample: \(glucoseData.datetime)"
                logger.error(message)
                return nil
            }

            return Eversense365.GetGlucoseDataResponse(
                trend: glucoseData.trend,
                glucoseDatetime: glucoseData.datetime,
                glucoseInMgDl: glucoseData.glucoseInMgDl
            )
        } catch {
            logger.error("[E3] Failed to get recent glucose: \(error.localizedDescription)")
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
            cgmManager.state.lastCalibration = Date.fromComponents(
                date: lastCalibrationDate.date,
                time: lastCalibrationTime.time
            )

            // Get next calibration datetime
            let nextCalibrationDate: GetNextCalibrationDateResponse = try await peripheralManager
                .write(GetNextCalibrationDatePacket())
            let nextCalibrationTime: GetNextCalibrationTimeResponse = try await peripheralManager
                .write(GetNextCalibrationTimePacket())
            cgmManager.state.nextCalibration = Date.fromComponents(
                date: nextCalibrationDate.date,
                time: nextCalibrationTime.time
            )

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
            let calibrationReadiness: GetCalibrationReadinessResponse = try await peripheralManager
                .write(GetCalibrationReadinessPacket())
            cgmManager.state.calibrationCount = calibrationCount.value
            cgmManager.state.calibrationPhase = calibrationPhase.phase
            cgmManager.state.calibrationReadiness = calibrationReadiness.calibrationReadiness

            let insertionDate: GetInsertionDateResponse = try await peripheralManager.write(GetInsertionDatePacket())
            let insertionTime: GetInsertionTimeResponse = try await peripheralManager.write(GetInsertionTimePacket())
            cgmManager.state.activatedAt = Date.fromComponents(
                date: insertionDate.insertionDate,
                time: insertionTime.insertionTime
            )
            cgmManager.state.expiresAt = cgmManager.state.activatedAt.addingTimeInterval(.days(180))

            // Write the fake app version
            if let appVersion = SetAppVersionPacket.parseAppVersion(version: fakeAppVersion) {
                let _: SetAppVersionResponse = try await peripheralManager
                    .write(SetAppVersionPacket(appVersion: appVersion))
            }

            // Get glucose alarms & status
            let glucoseAlarmsStatus: GetGlucoseAlertsAndStatusPacketResonse = try await peripheralManager
                .write(GetGlucoseAlertsAndStatusPacket())
            cgmManager.state.activeAlarms = glucoseAlarmsStatus.alarms

            let vibrateMode: GetVibrateModeResponse = try await peripheralManager
                .write(GetVibrateModePacket())
            cgmManager.state.vibrateMode = vibrateMode.value

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
            let predictionFallingThreshold: GetPredictiveFallingThresholdResponse = try await peripheralManager
                .write(GetPredictiveFallingThresholdPacket())
            let predictionRisingThreshold: GetPredictiveRisingThresholdResponse = try await peripheralManager
                .write(GetPredictiveRisingThresholdPacket())
            cgmManager.state.isPredictionLowEnabled = isPredictionLowEnabled.value
            cgmManager.state.isPredictionHighEnabled = isPredictionHighEnabled.value
            cgmManager.state.predictionFallingInterval = predictionFallingInterval.value
            cgmManager.state.predictionRisingInterval = predictionRisingInterval.value
            cgmManager.state.predictionFallingThreshold = predictionFallingThreshold.value
            cgmManager.state.predictionRisingThreshold = predictionRisingThreshold.value

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
        peripheralManager: PeripheralManager,
        data: TransmitterSettings
    ) async {
        do {
            let _: SetVibrateModeResponse = try await peripheralManager.write(SetVibrateModePacket(enabled: data.vibrationMode))

            let _: SetHighGlucoseAlarmEnabledResponse = try await peripheralManager
                .write(SetHighGlucoseAlarmEnabledPacket(enabled: data.glucoseHighEnabled))
            let _: SetHighGlucoseAlarmResponse = try await peripheralManager
                .write(SetHighGlucoseAlarmPacket(value: data.glucoseHighInMgDl))
            let _: SetLowGlucoseAlarmResponse = try await peripheralManager
                .write(SetLowGlucoseAlarmPacket(value: data.glucoseLowInMgDl))

            let _: SetRateRisingEnabledResponse = try await peripheralManager
                .write(SetRateRisingEnabledPacket(enabled: data.rateRisingEnabled))
            let _: SetRateRisingThresholdResponse = try await peripheralManager
                .write(SetRateRisingThresholdPacket(value: data.rateRisingThreshold))
            let _: SetRateFallingEnabledResponse = try await peripheralManager
                .write(SetRateFallingEnabledPacket(enabled: data.rateFallingEnabled))
            let _: SetRateFallingThresholdResponse = try await peripheralManager
                .write(SetRateFallingThresholdPacket(value: data.rateFallingThreshold))

            let _: SetPredictionHighEnabledResponse = try await peripheralManager
                .write(SetPredictionHighEnabledPacket(enabled: data.predictiveHighEnabled))
            let _: SetPredictionHighTimeResponse = try await peripheralManager
                .write(SetPredictionHighTimePacket(time: data.predictiveHighTime))
            let _: SetPredictionHighThresholdResponse = try await peripheralManager
                .write(SetPredictionHighThresholdPacket(value: data.predictiveHighThreshold))
            let _: SetPredictionLowEnabledResponse = try await peripheralManager
                .write(SetPredictionLowEnabledPacket(enabled: data.predictiveLowEnabled))
            let _: SetPredictionLowTimeResponse = try await peripheralManager
                .write(SetPredictionLowTimePacket(time: data.predictiveLowTime))
            let _: SetPredictionLowThresholdResponse = try await peripheralManager
                .write(SetPredictionLowThresholdPacket(value: data.predictiveLowThreshold))

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
