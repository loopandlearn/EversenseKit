import LoopKit

public struct CGMReadingResult : Codable, Equatable {
    let glucoseInMgDl: UInt16
    let datetime: Date
    let trend: GlucoseTrend?
    let raw: String
}
