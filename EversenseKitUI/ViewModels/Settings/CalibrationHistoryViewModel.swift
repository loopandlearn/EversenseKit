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
        
        
    }
}
