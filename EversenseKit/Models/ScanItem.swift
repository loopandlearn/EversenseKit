import CoreBluetooth

struct ScanItem {
    let name: String
    let rssi: Int
    let peripheral: CBPeripheral
}

enum ScanError {
    case noCbCentralManager

    var describe: String {
        switch self {
        case .noCbCentralManager:
            return "No CBCentralManager available"
        }
    }
}
