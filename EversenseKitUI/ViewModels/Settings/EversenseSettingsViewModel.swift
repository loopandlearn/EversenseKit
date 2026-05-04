import HealthKit
import SwiftUI

struct ActiveAlarmItem: Identifiable {
    let id = UUID()
    let code: Alarm
    let codeRaw: UInt8
    let priority: UInt8
}

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
    @Published var nextCalibrationProcessColor: Color = .accentColor
    @Published var nextCalibrationDays: Double = 0
    @Published var nextCalibrationHours: Double = 0
    @Published var nextCalibrationMinutes: Double = 0
    @Published var batteryLevel: String = "0"
    @Published var batteryPercentage: Double = 0
    @Published var signalStrength: String = ""
    @Published var connectionStatus: String = ""
    @Published var lastSync: String = ""
    @Published var insertionDate: String = ""
    @Published var insertionTime: String = ""
    @Published var activeAlarm: [ActiveAlarmItem] = []
    @Published var calibrationReadiness: CalibrationReadiness = .Unknown
    @Published var is365: Bool = false
    @Published var forceSyncing: Bool = false

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
    public let allowCalibrations = FeatureFlags.ALLOW_CALIBRATION
    public let deleteCgm: () -> Void
    public let toTransmitterSettings: () -> Void
    public let toPlacementGuide: () -> Void
    public let toCalibration: () -> Void
    public let toCalibrationHistory: () -> Void
    public let toAlertHistory: () -> Void
    init(
        cgmManager: EversenseCGMManager?,
        deleteCgm: @escaping () -> Void,
        toTransmitterSettings: @escaping () -> Void,
        toPlacementGuide: @escaping () -> Void,
        toCalibration: @escaping () -> Void,
        toCalibrationHistory: @escaping () -> Void,
        toAlertHistory: @escaping () -> Void,
    ) {
        self.cgmManager = cgmManager
        self.deleteCgm = deleteCgm
        self.toTransmitterSettings = toTransmitterSettings
        self.toPlacementGuide = toPlacementGuide
        self.toCalibration = toCalibration
        self.toCalibrationHistory = toCalibrationHistory
        self.toAlertHistory = toAlertHistory

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
        forceSyncing = true
        cgmManager?.heartbeathOperation(force: true) {
            DispatchQueue.main.async {
                self.forceSyncing = false
            }
        }
    }
}

extension EversenseSettingsViewModel: StateObserver {
    func stateDidUpdate(_ state: EversenseCGMState) {
        transmitterModel = state.modelStr ?? "UNKNOWN"
        is365 = state.is365
        transmitterName = state.bleNameString ?? ""
        connectionStatus = state.connectionStatus.title
        currentPhase = state.calibrationPhase.getTitle(calibrationMode: state.calibrationMode)
        calibrationReadiness = state.calibrationReadiness
        insertionDate = dateFormatter.string(from: state.activatedAt)
        insertionTime = timeFormatter.string(from: state.activatedAt)
        signalStrength = state.signalStrength.title
        activeAlarm = state.activeAlarms
            .filter { $0.code.type != .Info }
            .map { item in ActiveAlarmItem(code: item.code, codeRaw: item.codeRaw, priority: item.priority) }

        if state.batteryPercentage == 255 {
            batteryLevel = String(localized: "Charging", comment: "battery charging")
            batteryPercentage = 1.1
        } else {
            batteryLevel = "\(state.batteryPercentage)"
            batteryPercentage = Double(state.batteryPercentage) / 100
        }

        if let value = state.recentGlucoseInMgDl {
            lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(value))
        }

        if let value = state.recentGlucoseDateTime {
            lastMeasurementDatetime = timeFormatter.string(from: value)
        }

        if let value = state.lastSynced {
            lastSync = timeFormatter.string(from: value)
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
            nextCalibrationHours = max(floor(nextCalibrationIn.truncatingRemainder(dividingBy: .days(1)) / .hours(1)), 0)
            nextCalibrationMinutes = max(floor(nextCalibrationIn.truncatingRemainder(dividingBy: .hours(1)) / .minutes(1)), 0)

            if nextCalibrationProcess == 1 {
                nextCalibrationProcessColor = .red
            } else if nextCalibrationIn <= .hours(24) {
                nextCalibrationProcessColor = .orange
            } else {
                nextCalibrationProcessColor = .accentColor
            }
        }
    }
}
