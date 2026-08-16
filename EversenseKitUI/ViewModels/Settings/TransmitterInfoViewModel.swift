class TransmitterInfoViewModel: ObservableObject {
    @Published var transmitterName: String = ""
    @Published var currentPhase: String = ""
    @Published var signalStrength: String = ""
    @Published var batteryLevel: String = ""

    @Published var insertionDate: String = ""
    @Published var insertionTime: String = ""

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

    private let cgmManager: EversenseCGMManager
    init(cgmManager: EversenseCGMManager) {
        self.cgmManager = cgmManager

        stateDidUpdate(cgmManager.state)
        cgmManager.addStateObserver(state: self, queue: DispatchQueue.main)
    }

    deinit {
        cgmManager.removeStateObserver(state: self)
    }
}

extension TransmitterInfoViewModel: StateObserver {
    func stateDidUpdate(_ state: EversenseCGMState) {
        transmitterName = state.bleNameString ?? ""
        currentPhase = state.calibrationPhase.getTitle(calibrationMode: state.calibrationMode)
        insertionDate = dateFormatter.string(from: state.activatedAt)
        insertionTime = timeFormatter.string(from: state.activatedAt)
        signalStrength = state.signalStrength.title

        if state.batteryPercentage == 255 {
            batteryLevel = String(localized: "Charging", comment: "battery charging")
        } else {
            batteryLevel = "\(state.batteryPercentage)%"
        }
    }
}
