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

    func cleanup() {
        logger.info("Cleaning up CGMManager")
        state.bleNameString = nil

        bluetoothManager.stopScan()
        bluetoothManager.disconnect()
    }

    public var isOnboarded: Bool {
        state.isOnboarded
    }

    public var debugDescription: String {
        state.debugDescription
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

    public func delete(completion: @escaping () -> Void) {
        cleanup()
        notifyDelegateOfDeletion(completion: completion)
    }
}

extension EversenseCGMManager {
    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        completion(.noData)
        heartbeathOperation {}
    }

    /// Responsible for handling fetching Glucose data when ready
    func heartbeathOperation(force: Bool = true, completion: (() -> Void)? = nil) {
        let lastGlucoseTimestamp = max(
            state.recentGlucoseDateTime ?? Date.distantPast,
            Date.now.addingTimeInterval(.hours(-4))
        )

        if !force, Date.now.timeIntervalSince(lastGlucoseTimestamp) < .minutes(4.5) {
            logger.warning("Skipping sync, glucose is still fresh - \(Date.now.timeIntervalSince(lastGlucoseTimestamp))s")
            return
        }

        bluetoothManager.ensureConnected { error in
            if let internalError = error {
                self.logger.error("Failed to connect to CGM: \(internalError.describe)")
                completion?()
                return
            }

            guard let peripheralManager = self.bluetoothManager.peripheralManager else {
                self.logger.error("No peripheralManager")
                completion?()
                return
            }

            var samples: [CGMReading] = []
            if !self.state.is365 {
                samples = EversenseE3.readGlucoseData(
                    peripheralManager: peripheralManager,
                    cgmManager: self,
                    lastGlucoseTimestamp: lastGlucoseTimestamp
                )
                if !samples.isEmpty {
                    EversenseE3.fullSync(peripheralManager: peripheralManager, cgmManager: self)
                }
            } else {
                samples = Eversense365.readGlucoseData(
                    peripheralManager: peripheralManager,
                    cgmManager: self,
                    lastGlucoseTimestamp: lastGlucoseTimestamp
                )
                if !samples.isEmpty {
                    Eversense365.fullSync(peripheralManager: peripheralManager, cgmManager: self)
                }
            }

            if !samples.isEmpty {
                self.state.readingsToUpload += samples

                if let lastReading = samples.last {
                    self.state.recentGlucoseInMgDl = lastReading.glucoseInMgDl
                    self.state.recentGlucoseDateTime = lastReading.datetime
                    self.state.recentGlucoseTrend = lastReading.trend ?? .flat
                }

                self.notifyStateDidChange()

                self.delegate.notify { delegate in
                    guard let delegate else {
                        return
                    }

                    delegate.cgmManager(self, hasNew: .newData(
                        samples.map {
                            NewGlucoseSample(
                                cgmManager: self,
                                value: $0.glucoseInMgDl,
                                trend: $0.trend,
                                dateTime: $0.datetime
                            )
                        }
                    ))
                }
            }

            Task {
                if self.state.readingsToUpload.isEmpty {
                    self.logger.debug("Nothing to upload...")
                    return
                }

                guard await DMSApi.uploadGlucoseReadings(cgmManager: self, readings: self.state.readingsToUpload) else {
                    self.logger.warning("Failed to upload readings")
                    return
                }

                guard let lastReading = self.state.readingsToUpload.last,
                      await DMSApi.uploadCurrentValues(cgmManager: self, reading: lastReading)
                else {
                    self.logger.warning("Failed to upload current reading")
                    return
                }

                guard await DMSApi.uploadDeviceEvents(cgmManager: self, readings: self.state.readingsToUpload) else {
                    self.logger.warning("Failed to upload device events")
                    return
                }

                self.state.readingsToUpload = []
                self.notifyStateDidChange()
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
