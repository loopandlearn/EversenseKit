public class ActiveAlarm: Codable, Equatable {
    let code: Alarm
    let flag: UInt8
    let priority: UInt8

    init(code: Alarm, flag: UInt8, priority: UInt8) {
        self.code = code
        self.flag = flag
        self.priority = priority
    }

    public static func == (lhs: ActiveAlarm, rhs: ActiveAlarm) -> Bool {
        lhs.code == rhs.code && lhs.flag == rhs.flag && lhs.priority == rhs.priority
    }
}
