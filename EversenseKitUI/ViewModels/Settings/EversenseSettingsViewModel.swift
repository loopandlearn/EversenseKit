import HealthKit
import SwiftUI

class EversenseSettingsViewModel: ObservableObject {
    @Published var transmitterModel: String = ""
    @Published var transmitterName: String = ""
    @Published var currentPhase: String = ""
    @Published var lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 0)
    @Published var lastMeasurementDatetime: String = ""
    @Published var lastCalibrationTime: String = ""
    @Published var lastCalibrationDate: String = ""
    @Published var nextCalibrationTime: String = ""
    @Published var nextCalibrationDate: String = ""
    @Published var nextCalibrationProcess: Double = 0
    @Published var nextCalibrationDays: Double = 0
    @Published var nextCalibrationHours: Double = 0
    @Published var nextCalibrationMinutes: Double = 0
    @Published var batteryLevel: String = "0%"
    @Published var signalStrength: String = ""
    @Published var connectionStatus: String = ""
    @Published var is365: Bool = false

    @Published var showingDeleteConfirmation: Bool = false

    private let timeFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    private let dateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    private let logger = EversenseLogger(category: "SettingsViewModel")

    private let cgmManager: EversenseCGMManager?
    public let deleteCgm: () -> Void
    public let toTransmitterSettings: () -> Void
    public let toPlacementGuide: () -> Void
    init(
        cgmManager: EversenseCGMManager?,
        deleteCgm: @escaping () -> Void,
        toTransmitterSettings: @escaping () -> Void,
        toPlacementGuide: @escaping () -> Void
    ) {
        self.cgmManager = cgmManager
        self.deleteCgm = deleteCgm
        self.toTransmitterSettings = toTransmitterSettings
        self.toPlacementGuide = toPlacementGuide

        guard let cgmManager = cgmManager else {
            return
        }

        cgmManager.addStateObserver(state: self, queue: .main)
        stateDidUpdate(cgmManager.state)
    }

    func getLogs() -> [URL] {
        if let cgmManager = self.cgmManager {
            logger.info(cgmManager.state.debugDescription)
        }
        return logger.getDebugLogs()
    }

    public func readGlucose() {
        cgmManager?.heartbeathOperation(force: true)
    }
}

extension EversenseSettingsViewModel: StateObserver {
    func stateDidUpdate(_ state: EversenseCGMState) {
        transmitterModel = state.modelStr ?? "UNKNOWN"
        is365 = state.is365
        transmitterName = state.bleNameString
        connectionStatus = state.connectionStatus.title
        currentPhase = state.calibrationPhase.getTitle(calibrationMode: state.calibrationMode)

        signalStrength = state.signalStrength.title
        batteryLevel = "\(state.batteryPercentage)%"

        if let value = state.recentGlucoseInMgDl {
            lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(value))
        }

        if let value = state.recentGlucoseDateTime {
            lastMeasurementDatetime = timeFormatter.string(from: value)
        }

        if let lastCalibration = state.lastCalibration, let nextCalibration = state.nextCalibration {
            let calibrationPeriod = state.calibrationMode.toPeriod()
            let calibrationAge = lastCalibration.timeIntervalSinceNow * -1
            let nextCalibrationIn = calibrationPeriod - calibrationAge

            lastCalibrationDate = dateFormatter.string(from: lastCalibration)
            lastCalibrationTime = timeFormatter.string(from: lastCalibration)
            nextCalibrationDate = dateFormatter.string(from: nextCalibration)
            nextCalibrationTime = timeFormatter.string(from: nextCalibration)
            nextCalibrationProcess = min(calibrationAge / calibrationPeriod, 1)

            nextCalibrationDays = max(floor(nextCalibrationIn / .days(1)), 0)
            nextCalibrationHours = max(nextCalibrationIn.truncatingRemainder(dividingBy: .days(1)) / .hours(1), 0)
            nextCalibrationMinutes = max(nextCalibrationIn.truncatingRemainder(dividingBy: .hours(1)) / .minutes(1), 0)
        }
    }
}
