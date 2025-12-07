import HealthKit
import LoopKit

protocol StateObserver: AnyObject {
    func stateDidUpdate(_ state: EversenseCGMState)
}

public class EversenseCGMManager: CGMManager {
    public static var pluginIdentifier: String = "EversenseKit"

    private let logger = EversenseLogger(category: "CGMManager")
    internal let bluetoothManager: BluetoothManager

    public var state: EversenseCGMState
    public var rawState: RawStateValue {
        state.rawValue
    }

    public var managedDataInterval: TimeInterval? {
        .hours(3)
    }

    public var providesBLEHeartbeat: Bool {
        true
    }

    public var shouldSyncToRemoteService: Bool {
        true
    }

    public var glucoseDisplay: (any LoopKit.GlucoseDisplayable)? {
        GlucoseDisplay(state: state)
    }

    public var cgmManagerStatus: LoopKit.CGMManagerStatus {
        LoopKit.CGMManagerStatus(
            hasValidSensorSession: state.isOnboarded && state.recentGlucoseDateTime != nil,
            lastCommunicationDate: state.lastSynced,
            device: device
        )
    }

    internal var device: HKDevice {
        HKDevice(
            name: state.modelStr,
            manufacturer: "Senseonics",
            model: nil,
            hardwareVersion: nil,
            firmwareVersion: state.version,
            softwareVersion: state.extVersion,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    public weak var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    public var delegateQueue: DispatchQueue! {
        get {
            delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }

    private let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    private let stateObservers = WeakSynchronizedSet<StateObserver>()

    public let managerIdentifier: String = "EversenseCGMManager"

    public var localizedTitle: String {
        if state.is365 {
            return "Eversense 365"
        } else {
            return "Eversense E3"
        }
    }

    public required init?(rawState: RawStateValue) {
        guard let state = EversenseCGMState(rawValue: rawState) else {
            return nil
        }

        self.state = state
        bluetoothManager = BluetoothManager()
        bluetoothManager.cgmManager = self
    }

    public var isOnboarded: Bool {
        state.isOnboarded
    }

    public var debugDescription: String {
        let lines = [
            "## EverSense CGM:",
            state.debugDescription
        ]
        return lines.joined(separator: "\n")
    }

    func addStateObserver(state: StateObserver, queue: DispatchQueue) {
        stateObservers.insert(state, queue: queue)
    }

    public func acknowledgeAlert(alertIdentifier _: LoopKit.Alert.AlertIdentifier, completion: @escaping ((any Error)?) -> Void) {
        completion(nil)
    }

    public func getSoundBaseURL() -> URL? {
        nil
    }

    public func getSounds() -> [LoopKit.Alert.Sound] {
        []
    }
}

extension EversenseCGMManager {
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        logger.info("Starting fetchNewDataIfNeeded...")

        guard let peripheralManager = bluetoothManager.peripheralManager else {
            logger.error("No peripheralManager")
            completion(.noData)
            return
        }

        delegateQueue.async {
            var lastGlucoseTimestamp = self.cgmManagerDelegate?.startDateToFilterNewData(for: self) ?? Date.now
                .addingTimeInterval(.hours(-4))

            if lastGlucoseTimestamp > Date.now.addingTimeInterval(.hours(-4)) {
                self.logger.warning("Limiting lastGlucoseTimestamp to 4 hours ago")
                lastGlucoseTimestamp = Date.now.addingTimeInterval(.hours(-4))
            }

            self.bluetoothManager.ensureConnected { error in
                if let internalError = error {
                    self.logger.error("Failed to connect to CGM: \(internalError.describe)")
                    completion(.error(internalError))
                    return
                }

                var samples: [NewGlucoseSample] = []
                if !self.state.is365 {
                    samples = await EversenseE3.readGlucoseData(
                        peripheralManager: peripheralManager,
                        cgmManager: self,
                        lastGlucoseTimestamp: lastGlucoseTimestamp
                    )
                    await EversenseE3.fullSync(peripheralManager: peripheralManager, cgmManager: self)
                } else {
                    samples = await Eversense365.readGlucoseData(
                        peripheralManager: peripheralManager,
                        cgmManager: self,
                        lastGlucoseTimestamp: lastGlucoseTimestamp
                    )
                    await Eversense365.fullSync(peripheralManager: peripheralManager, cgmManager: self)
                }

                if samples.isEmpty {
                    completion(.noData)
                } else {
                    completion(.newData(samples))
                }
            }
        }

        completion(.noData)
    }

    /// Responsible for handling fetching Glucose data when ready
    func heartbeathOperation(completion: (() -> Void)? = nil) {
        fetchNewDataIfNeeded { samples in

            if case let .newData(data) = samples {
                self.delegate.notify { delegate in
                    delegate?.cgmManager(self, hasNew: .newData(data))
                }
            }

            completion?()
        }
    }

    func notifyStateDidChange() {
        stateObservers.forEach { observer in
            observer.stateDidUpdate(self.state)
        }

        delegate.notify { cgmManagerDelegate in
            guard let cgmManagerDelegate = cgmManagerDelegate else {
                self.logger.warning("Skip notifying delegate as no delegate set...")
                return
            }

            cgmManagerDelegate.cgmManagerDidUpdateState(self)
        }
    }
}
