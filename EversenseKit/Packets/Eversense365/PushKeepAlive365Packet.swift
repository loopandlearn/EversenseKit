extension Eversense365 {
    class PushKeepAliveResponse {
        let batteryLevel: UInt8
        let mostRecenteGlucoseDatetime: Date
        
        init(batteryLevel: UInt8, mostRecenteGlucoseDatetime: Date) {
            self.batteryLevel = batteryLevel
            self.mostRecenteGlucoseDatetime = mostRecenteGlucoseDatetime
        }
    }
    
    class PushKeepAlivePacket : BasePacket {
        typealias T = PushKeepAliveResponse
        
        var responseType: UInt8 {
            0
        }
        
        var responseId: UInt8? {
            nil
        }
        
        func getRequestData() -> Data {
            return Data()
        }
        
        func parseResponse(data: Data) -> PushKeepAliveResponse {
            return PushKeepAliveResponse(
                batteryLevel: data[Offset.BATTERY_LEVEL],
                mostRecenteGlucoseDatetime: Date.fromUnix2000(data: data.subdata(in: Offset.MOST_RECENT_GLUCOSE_DATETIME_START..<Offset.MOST_RECENT_GLUCOSE_DATETIME_END))
            )
        }
        
        enum Offset {
            static let BATTERY_LEVEL = 10
            static let MOST_RECENT_GLUCOSE_DATETIME_START = 11
            static let MOST_RECENT_GLUCOSE_DATETIME_END = 19
        }
    }
}
