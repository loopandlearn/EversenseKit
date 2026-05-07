public class ActiveAlarm: Codable, Equatable {
    let code: Alarm
    let codeRaw: UInt8
    let datetime: Date
    let glucoseInMgDl: UInt16
    let flag: UInt8
    let priority: UInt8

    init(code: Alarm, codeRaw: UInt8, glucoseInMgDl: UInt16, flag: UInt8, priority: UInt8) {
        self.code = code
        self.codeRaw = codeRaw
        datetime = Date.now
        self.glucoseInMgDl = glucoseInMgDl
        self.flag = flag
        self.priority = priority
    }

    public static func == (lhs: ActiveAlarm, rhs: ActiveAlarm) -> Bool {
        lhs.code == rhs.code && lhs.codeRaw == rhs.codeRaw && lhs.flag == rhs.flag && lhs.priority == rhs.priority
    }
}
