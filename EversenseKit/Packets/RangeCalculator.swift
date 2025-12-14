enum RangeCalculator {
    public static func calculateGlucoseRange(rangeFrom: UInt32, rangeTo: UInt32, lastGlucoseTimestamp: Date) -> RangeCalculation {
        let timeDiff = (Date.now.timeIntervalSince(lastGlucoseTimestamp) / TimeInterval.minutes(5)).rounded(.up)

        // Maximum page fetch = 20
        let pageCount = min(UInt32(timeDiff + 2), 20)
        var from = rangeTo - pageCount
        if from < 0 || from < rangeFrom {
            from = rangeFrom
        }

        return RangeCalculation(from: from, to: rangeTo)
    }
}

struct RangeCalculation {
    let from: UInt32
    let to: UInt32
}
