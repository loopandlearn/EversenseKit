import LoopKit

public struct CGMReading: Codable, Equatable {
    let glucoseInMgDl: UInt16
    let datetime: Date
    let trend: GlucoseTrend?
    let raw: String
}

public struct CalibrationEvent {
    let glucoseInMgDl: UInt16
    let datetime: Date
}
