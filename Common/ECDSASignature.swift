enum DERSignatureError: Error {
    case invalidFormat
    case unsupportedLength
}

func parseECDSASignature(_ der: Data) throws -> Data {
    var index = 0
    let bytes = [UInt8](der)

    func readByte() throws -> UInt8 {
        guard index < bytes.count else { throw DERSignatureError.invalidFormat }
        defer { index += 1 }
        return bytes[index]
    }

    func readLength() throws -> Int {
        let first = try readByte()
        if first & 0x80 == 0 {
            return Int(first)
        }

        let count = Int(first & 0x7F)
        guard count > 0, count <= 2 else {
            throw DERSignatureError.unsupportedLength
        }

        var length = 0
        for _ in 0 ..< count {
            length = (length << 8) | Int(try readByte())
        }
        return length
    }

    // Expect SEQUENCE
    guard try readByte() == 0x30 else {
        throw DERSignatureError.invalidFormat
    }
    _ = try readLength()

    // Read INTEGER r
    guard try readByte() == 0x02 else {
        throw DERSignatureError.invalidFormat
    }
    let rLength = try readLength()
    var r = Data(bytes[index ..< index + rLength])
    index += rLength

    // Read INTEGER s
    guard try readByte() == 0x02 else {
        throw DERSignatureError.invalidFormat
    }
    let sLength = try readLength()
    var s = Data(bytes[index ..< index + sLength])

    if r.first == 0 { r.removeFirst() }
    if s.first == 0 { s.removeFirst() }

    return r + s
}
