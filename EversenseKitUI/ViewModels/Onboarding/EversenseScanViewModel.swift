import LoopKit
import SwiftUI

struct ScanResultItem: Identifiable {
    let id = UUID()
    var name: String
    let bleIdentifier: String
}

class EversenseScanViewModel: ObservableObject {
    @Published var results: [ScanResultItem] = []
    @Published var connectingTo: String = ""
    @Published var error: String = ""

    private let logger = EversenseLogger(category: "ScanViewModel")

    private var actualResults: [ScanItem] = []

    private let cgmManager: EversenseCGMManager
    private let nextStep: () -> Void
    init(_ cgmManager: EversenseCGMManager, _ nextStep: @escaping () -> Void) {
        self.cgmManager = cgmManager
        self.nextStep = nextStep

        start()
    }

    func start() {
        cgmManager.bluetoothManager.scan { item, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error.describe
                }
                return
            }
            guard let item = item,
                  !self.results.contains(where: { $0.bleIdentifier == item.peripheral.identifier.uuidString })
            else {
                return
            }

            DispatchQueue.main.async {
                self.results.append(ScanResultItem(
                    name: item.name,
                    bleIdentifier: item.peripheral.identifier.uuidString
                ))
                self.actualResults.append(item)
            }
        }
    }

    func stopScan() {
        cgmManager.bluetoothManager.stopScan()
    }

    func connect(_ item: ScanResultItem) {
        guard let scanItem = actualResults.first(where: { $0.peripheral.identifier.uuidString == item.bleIdentifier })
        else {
            error = "No cgmManager"
            return
        }

        logger.info("Connecting to \(scanItem.name)...")

        connectingTo = scanItem.name
        cgmManager.bluetoothManager.peripheral = scanItem.peripheral

        cgmManager.bluetoothManager.ensureConnected { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.error = error.describe
                    self.connectingTo = ""
                }
                return
            }

            self.nextStep()
        }
    }
}
