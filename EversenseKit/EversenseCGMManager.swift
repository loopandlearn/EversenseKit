import HealthKit
import LoopKit

protocol StateObserver: AnyObject {
    func stateDidUpdate(_ state: EversenseCGMState)
}

public class EversenseCGMManager: CGMManager {
    public static var pluginIdentifier: String = "EversenseKit"

    private let logger = EversenseLogger(category: "CGMManager")
    private var isFetchingData = false
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
        logger.debug("Starting fetchNewDataIfNeeded...")

        guard !isFetchingData else {
            logger.error("Is already running...")
            completion(.noData)
            return
        }

        completion(.noData)

        if bluetoothManager.peripheral == nil || bluetoothManager.peripheral?.state != .connected {
            bluetoothManager.ensureConnected { _ in }
        }
    }

    /// Responsible for handling fetching Glucose data when ready
    func heartbeathOperation(force: Bool = true, completion: (() -> Void)? = nil) {
        var lastGlucoseTimestamp = state.recentGlucoseDateTime ?? Date.now
            .addingTimeInterval(.hours(-4))

        if !force, Date.now.timeIntervalSince(lastGlucoseTimestamp) < .minutes(4.5) {
            logger.warning("Skipping sync, glucose is still fresh - \(Date.now.timeIntervalSince(lastGlucoseTimestamp))s")
            return
        }

        if lastGlucoseTimestamp > Date.now.addingTimeInterval(.hours(-4)) {
            logger.warning("Limiting lastGlucoseTimestamp to 4 hours ago - \(lastGlucoseTimestamp)")
            lastGlucoseTimestamp = Date.now.addingTimeInterval(.hours(-4))
        }

        isFetchingData = true
        delegateQueue.async {
            let lastGlucoseTimestamp = lastGlucoseTimestamp
            let this = self

            self.bluetoothManager.ensureConnected { error in
                if let internalError = error {
                    self.isFetchingData = false
                    self.logger.error("Failed to connect to CGM: \(internalError.describe)")
                    completion?()
                    return
                }

                guard let peripheralManager = self.bluetoothManager.peripheralManager else {
                    self.logger.error("No peripheralManager")
                    self.isFetchingData = false
                    completion?()
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

                self.isFetchingData = false
                if !samples.isEmpty {
                    self.delegate.notify { delegate in
                        delegate?.cgmManager(this, hasNew: .newData(samples))
                    }
                }

                completion?()
            }
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
