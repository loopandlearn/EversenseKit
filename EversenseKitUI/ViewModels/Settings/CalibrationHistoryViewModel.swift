import SwiftUI

class CalibrationHistoryViewModel: ObservableObject {
    @Published var isLoading = true

    private let logger = EversenseLogger(category: "CalibrationHistoryViewModel")
    private let cgmManager: EversenseCGMManager?
    init(cgmManager: EversenseCGMManager?) {
        self.cgmManager = cgmManager
    }

    func start() {
        guard let cgmManager = cgmManager else {
            logger.error("No CGMManager...")
            return
        }

        Task {
            do {
                if cgmManager.state.is365 {
                    logger.error("NOT IMPLEMENTED....")
                } else {
                    let rangeResponse: EversenseE3.GetLogRangeResponse = try await cgmManager.bluetoothManager
                        .write(EversenseE3.GetLogRangePacket(type: .calibration))
                    let range = RangeCalculator.calculateRange(rangeFrom: rangeResponse.rangeFrom, rangeTo: rangeResponse.rangeTo)

//                    for index in range.from...range.to {
//                        let calibrationItem = try
//                    }
                }
            } catch {
                logger.error("Failed to fetch calibration history: \(error)")
            }
        }
    }
}
