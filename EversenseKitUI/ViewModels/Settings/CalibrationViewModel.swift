import HealthKit
import SwiftUI

class CalibrationViewModel: ObservableObject {
    @Published var glucose: UInt16
    @Published var time = Date.now
    @Published var isLoading = false
    @Published var error = ""

    let allowedGlucoseValuesMgDl = Array(UInt16(60) ... UInt16(400))
    let allowedGlucoseValuesMmolL = Array(UInt16(33) ... UInt16(220))

    private let logger = EversenseLogger(category: "CalibrationViewModel")
    private let cgmManager: EversenseCGMManager?
    private let done: () -> Void
    private let unit: HKUnit
    public let allowCalibrations = FeatureFlags.ALLOW_CALIBRATION
    init(cgmManager: EversenseCGMManager?, _ unit: HKUnit, _ done: @escaping () -> Void) {
        self.cgmManager = cgmManager
        self.unit = unit
        self.done = done
        glucose = unit == .milligramsPerDeciliter ? 100 : 56
    }

    func calibrate() {
        guard let cgmManager = cgmManager else {
            logger.warning("No CGMManager...")
            return
        }

        error = ""
        isLoading = true

        var glucose = glucose
        if unit == .millimolesPerLiter {
            let mgdl = HKQuantity(unit: unit, doubleValue: Double(glucose) / 10).doubleValue(for: .milligramsPerDeciliter)
            glucose = UInt16(mgdl)
        }

        Task {
            do {
                if cgmManager.state.is365 {
                    try await Eversense365.calibrateSensors(cgmManager: cgmManager, glucoseInMgDl: glucose, timestamp: time)
                } else {
                    try await EversenseE3.calibrateSensors(cgmManager: cgmManager, glucoseInMgDl: glucose, timestamp: time)
                }
                
                cgmManager.heartbeathOperation {}

                await MainActor.run {
                    self.isLoading = false
                }
            } catch {
                logger.error("Error during calibration: \(error)")

                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
