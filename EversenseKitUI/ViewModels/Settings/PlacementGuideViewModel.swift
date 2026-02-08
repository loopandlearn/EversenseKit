

class PlacementGuideViewModel: ObservableObject {
    @Published var strength: SignalStrength = .NoSignal
    @Published var strengthRaw: UInt16 = 0
    @Published var lastUpdate = ""

    private var running = true

    private let dateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()

    private let cgmManager: EversenseCGMManager?
    init(cgmManager: EversenseCGMManager?) {
        self.cgmManager = cgmManager

        guard let cgmManager = cgmManager else {
            return
        }

        stateDidUpdate(cgmManager.state)
        cgmManager.addStateObserver(state: self, queue: .main)

        // Start polling latest signal strength
        updateSignalStrength(cgmManager: cgmManager)
    }

    public func stop() {
        running = false
    }

    private func updateSignalStrength(cgmManager: EversenseCGMManager) {
        guard running else {
            return
        }

        Task {
            if cgmManager.state.is365 {
                Eversense365.updateSignalStrength(cgmManager: cgmManager)
            } else {
                EversenseE3.updateSignalStrength(cgmManager: cgmManager)
            }

            try await Task.sleep(nanoseconds: 500_000_000) // .5s waiting
            updateSignalStrength(cgmManager: cgmManager)
        }
    }
}

extension PlacementGuideViewModel: StateObserver {
    func stateDidUpdate(_ state: EversenseCGMState) {
        lastUpdate = dateFormatter.string(from: Date.now)
        strength = state.signalStrength

        if state.is365 {
            strengthRaw = min(state.signalStrengthRaw, 100)
        } else {
            strengthRaw = state.signalStrengthRaw / 20
        }
    }
}
