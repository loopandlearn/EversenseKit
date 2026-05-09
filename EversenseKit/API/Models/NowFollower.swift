struct NowFollower: Codable {
    let FollowerEmail: String
    let ReferenceName: String
    let Status: Int
}

struct NowFollowerUI: Identifiable {
    var id = UUID()
    let FollowerEmail: String
    let ReferenceName: String
    let isPending: Bool
}

/*
 {
     "UserID": 31582068,
     "FollowerID": "6d74b2bd-ad48-f111-ad11-0e0689900e23",
     "FollowerCode": "ebb0e5f8-9ac3-4ab6-a222-314787c31479",
     "FollowerEmail": "xxxxx@gmail.com",
     "ReferenceName": "Bastiaan Verhaar",
     "RemovedDate": "1970-01-01T00:00:00",
     "InvitationDate": "2026-05-05T18:10:50.847",
     "AcceptedDate": "1970-01-01T00:00:00",
     "OtherInfo": null,
     "FollowerUserId": 31596651,
     "Status": 1,
     "UserName": "xxxx@gmail.com",
     "FirstName": "Bastiaan",
     "LastName": "Verhaar",
     "ProfileImage": null,
     "CurrentGlucose": 0,
     "GlucoseTrend": 0,
     "CGTime": "0001-01-01T00:00:00",
     "Units": 0,
     "IsTransmitterConnected": null,
     "TxConnectionStatusTimestamp": null
   }
 */
