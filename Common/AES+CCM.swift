import Foundation

// MARK: - Errors

enum AESCCMError: Error {
    case invalidKeyLength
    case invalidIVLength // CCM nonce must be 7–13 bytes
    case invalidTagLength // must be 4,6,8,10,12,14,16
    case authenticationFailure // tag mismatch on decrypt
    case invalidCipherTextLength // ciphertext too short to contain tag
}

// MARK: - Public API

struct AESCCM {
    private let key: [UInt8]
    private let nonce: [UInt8] // 7–13 bytes
    private let tagLen: Int // 4,6,8,10,12,14,16
    private let aad: [UInt8]

    // L = 15 - nonce.count  (number of bytes used to encode the message length)
    private var L: Int { 15 - nonce.count }

    /// - Parameters:
    ///   - key:   16, 24, or 32 bytes (AES-128/192/256)
    ///   - nonce: 7–13 bytes
    ///   - tagLength: 4, 6, 8, 10, 12, 14, or 16
    ///   - additionalAuthenticatedData: authenticated but not encrypted bytes
    init(
        key: [UInt8],
        nonce: [UInt8],
        tagLength: Int = 8,
        additionalAuthenticatedData: [UInt8] = []
    ) throws {
        guard key.count == 16 || key.count == 24 || key.count == 32 else {
            throw AESCCMError.invalidKeyLength
        }
        guard nonce.count >= 7, nonce.count <= 13 else {
            throw AESCCMError.invalidIVLength
        }
        guard tagLength >= 4, tagLength <= 16, tagLength % 2 == 0 else {
            throw AESCCMError.invalidTagLength
        }
        self.key = key
        self.nonce = nonce
        tagLen = tagLength
        aad = additionalAuthenticatedData
    }

    /// Encrypt plaintext. Returns ciphertext || tag (tag is `tagLength` bytes).
    func encrypt(_ plaintext: [UInt8]) throws -> [UInt8] {
        let aes = try AESCipher(key: key)
        let mac = try cbcmac(plaintext: plaintext, aes: aes)
        let S0 = try ctrBlock(i: 0, aes: aes)
        let encTag = xorBytes(mac, S0, count: tagLen)

        var ct = [UInt8](repeating: 0, count: plaintext.count + tagLen)
        try encryptCTR(plaintext: plaintext, into: &ct, aes: aes)
        for i in 0 ..< tagLen { ct[plaintext.count + i] = encTag[i] }
        return ct
    }

    /// Decrypt and verify ciphertextWithTag (ciphertext || tag).
    /// Throws `AESCCMError.authenticationFailure` on tag mismatch.
    func decrypt(_ ciphertextWithTag: [UInt8]) throws -> [UInt8] {
        guard ciphertextWithTag.count >= tagLen else {
            throw AESCCMError.invalidCipherTextLength
        }
        let ctLen = ciphertextWithTag.count - tagLen
        let ciphertext = Array(ciphertextWithTag.prefix(ctLen))
        let encTag = Array(ciphertextWithTag.suffix(tagLen))

        let aes = try AESCipher(key: key)
        let S0 = try ctrBlock(i: 0, aes: aes)
        let expectedTag = xorBytes(encTag, S0, count: tagLen)

        var plaintext = [UInt8](repeating: 0, count: ctLen)
        try encryptCTR(plaintext: ciphertext, into: &plaintext, aes: aes)

        let computedTag = try cbcmac(plaintext: plaintext, aes: aes)

        guard constantTimeEqual(Array(computedTag.prefix(tagLen)), expectedTag) else {
            throw AESCCMError.authenticationFailure
        }
        return plaintext
    }

    // MARK: - CCM Internals

    /// Build and encrypt a single CTR counter block for counter value `i`.
    /// Counter block format (RFC 3610 §2.2):
    ///   byte 0  : flags = (L-1)  (bits 2-0; bits 7-3 = 0)
    ///   bytes 1…(15-L) : nonce
    ///   bytes (16-L)…15: counter `i` in big-endian, L bytes
    private func ctrBlock(i: Int, aes: AESCipher) throws -> [UInt8] {
        var block = [UInt8](repeating: 0, count: 16)
        block[0] = UInt8(L - 1)
        for j in 0 ..< nonce.count { block[1 + j] = nonce[j] }
        // Write i in big-endian into the last L bytes
        for j in 0 ..< L {
            block[15 - j] = UInt8((i >> (8 * j)) & 0xFF)
        }
        return try aes.encryptBlock(block)
    }

    /// XOR plaintext with CTR keystream starting at counter 1, write into `output`.
    private func encryptCTR(plaintext: [UInt8], into output: inout [UInt8], aes: AESCipher) throws {
        var ctr = 1
        var pos = 0
        while pos < plaintext.count {
            let S = try ctrBlock(i: ctr, aes: aes)
            let blockLen = min(16, plaintext.count - pos)
            for j in 0 ..< blockLen { output[pos + j] = plaintext[pos + j] ^ S[j] }
            pos += blockLen
            ctr += 1
        }
    }

    /// CBC-MAC per RFC 3610 §2.2. Returns a full 16-byte MAC (caller takes prefix tagLen).
    private func cbcmac(plaintext: [UInt8], aes: AESCipher) throws -> [UInt8] {
        let hasAAD = !aad.isEmpty
        // --- B0: flags || nonce || Q (message length in L bytes, big-endian) ---
        var flags: UInt8 = 0
        if hasAAD { flags |= 0x40 } // Adata bit
        flags |= UInt8(((tagLen - 2) / 2) & 0x07) << 3 // M' field
        flags |= UInt8((L - 1) & 0x07) // L' field

        var b0 = [UInt8](repeating: 0, count: 16)
        b0[0] = flags
        for j in 0 ..< nonce.count { b0[1 + j] = nonce[j] }
        let msgLen = plaintext.count
        for j in 0 ..< L { b0[15 - j] = UInt8((msgLen >> (8 * j)) & 0xFF) }

        var mac = try aes.encryptBlock(b0)

        // --- AAD encoding per RFC 3610 §2.2 ---
        if hasAAD {
            var encodedAAD = [UInt8]()
            let a = aad.count
            if a < 0xFF00 {
                encodedAAD.append(UInt8(a >> 8))
                encodedAAD.append(UInt8(a & 0xFF))
            } else if a < 0xFFFF_FFFF {
                encodedAAD += [0xFF, 0xFE]
                for j in (0 ..< 4).reversed() { encodedAAD.append(UInt8((a >> (8 * j)) & 0xFF)) }
            } else {
                encodedAAD += [0xFF, 0xFF]
                for j in (0 ..< 8).reversed() { encodedAAD.append(UInt8((a >> (8 * j)) & 0xFF)) }
            }
            encodedAAD += aad
            // Zero-pad to block boundary
            let rem = encodedAAD.count % 16
            if rem != 0 { encodedAAD += [UInt8](repeating: 0, count: 16 - rem) }

            for start in stride(from: 0, to: encodedAAD.count, by: 16) {
                let block = Array(encodedAAD[start ..< start + 16])
                mac = try aes.encryptBlock(xor16(mac, block))
            }
        }

        // --- Plaintext blocks ---
        if !plaintext.isEmpty {
            var padded = plaintext
            let rem = padded.count % 16
            if rem != 0 { padded += [UInt8](repeating: 0, count: 16 - rem) }
            for start in stride(from: 0, to: padded.count, by: 16) {
                let block = Array(padded[start ..< start + 16])
                mac = try aes.encryptBlock(xor16(mac, block))
            }
        }

        return mac // 16 bytes; caller truncates to tagLen
    }

    // MARK: - Helpers

    @inline(__always) private func xor16(_ a: [UInt8], _ b: [UInt8]) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: 16)
        for i in 0 ..< 16 { out[i] = a[i] ^ b[i] }
        return out
    }

    /// XOR the first `count` bytes of a and b.
    @inline(__always) private func xorBytes(_ a: [UInt8], _ b: [UInt8], count: Int) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: count)
        for i in 0 ..< count { out[i] = a[i] ^ b[i] }
        return out
    }

    /// Constant-time comparison to prevent timing side-channels.
    private func constantTimeEqual(_ a: [UInt8], _ b: [UInt8]) -> Bool {
        guard a.count == b.count else { return false }
        var diff: UInt8 = 0
        for i in 0 ..< a.count { diff |= a[i] ^ b[i] }
        return diff == 0
    }
}

// MARK: - Raw AES Block Cipher (FIPS 197)

/// Encrypts a single 16-byte block. Key sizes: 16 (AES-128), 24 (AES-192), 32 (AES-256).
struct AESCipher {
    // Expanded round keys — each element is one 16-byte round key stored column-major:
    // roundKeys[r][col*4 + row]
    private let roundKeys: [[UInt8]]

    init(key: [UInt8]) throws {
        guard key.count == 16 || key.count == 24 || key.count == 32 else {
            throw AESCCMError.invalidKeyLength
        }
        roundKeys = AESCipher.expandKey(key)
    }

    func encryptBlock(_ plaintext: [UInt8]) throws -> [UInt8] {
        precondition(plaintext.count == 16)
        var s = plaintext
        AESCipher.addRoundKey(&s, roundKeys[0])
        let nr = roundKeys.count - 1
        for r in 1 ..< nr {
            AESCipher.subBytes(&s)
            AESCipher.shiftRows(&s)
            AESCipher.mixColumns(&s)
            AESCipher.addRoundKey(&s, roundKeys[r])
        }
        AESCipher.subBytes(&s)
        AESCipher.shiftRows(&s)
        AESCipher.addRoundKey(&s, roundKeys[nr])
        return s
    }

    // MARK: Key Expansion (FIPS 197 §5.2)

    /// Rcon table — index 0 is an unused sentinel (0x8d) matching the standard layout;
    /// real values start at [1]. Key schedule uses rcon[i / Nk].
    private static let rcon: [UInt8] = [
        0x8D, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36,
        0x6C, 0xD8, 0xAB, 0x4D, 0x9A, 0x2F, 0x5E, 0xBC, 0x63, 0xC6, 0x97,
        0x35, 0x6A, 0xD4, 0xB3, 0x7D, 0xFA, 0xEF, 0xC5
    ]

    private static func expandKey(_ key: [UInt8]) -> [[UInt8]] {
        let nk = key.count / 4
        let nr = nk + 6
        let total = (nr + 1) * 4 // total 4-byte words

        var w = [[UInt8]](repeating: [0, 0, 0, 0], count: total)
        for i in 0 ..< nk {
            w[i] = [key[4 * i], key[4 * i + 1], key[4 * i + 2], key[4 * i + 3]]
        }
        for i in nk ..< total {
            var temp = w[i - 1]
            if i % nk == 0 {
                // RotWord then SubWord then XOR Rcon
                temp = [
                    sbox[Int(temp[1])],
                    sbox[Int(temp[2])],
                    sbox[Int(temp[3])],
                    sbox[Int(temp[0])]
                ]
                temp[0] ^= rcon[i / nk] // i/nk is 1-based here, matching rcon[1..n]
            } else if nk > 6, i % nk == 4 {
                temp = temp.map { sbox[Int($0)] }
            }
            w[i] = [
                w[i - nk][0] ^ temp[0],
                w[i - nk][1] ^ temp[1],
                w[i - nk][2] ^ temp[2],
                w[i - nk][3] ^ temp[3]
            ]
        }

        // Pack words into 16-byte round keys (column-major: byte = col*4+row)
        return (0 ... nr).map { r in
            var rk = [UInt8](repeating: 0, count: 16)
            for c in 0 ..< 4 { for b in 0 ..< 4 { rk[c * 4 + b] = w[r * 4 + c][b] } }
            return rk
        }
    }

    // MARK: Round Functions

    @inline(__always) private static func addRoundKey(_ s: inout [UInt8], _ rk: [UInt8]) {
        for i in 0 ..< 16 { s[i] ^= rk[i] }
    }

    @inline(__always) private static func subBytes(_ s: inout [UInt8]) {
        for i in 0 ..< 16 { s[i] = sbox[Int(s[i])] }
    }

    /// ShiftRows for column-major state: state[col*4 + row].
    /// Row r is shifted left by r positions.
    @inline(__always) private static func shiftRows(_ s: inout [UInt8]) {
        // Row 0: no shift
        // Row 1: left by 1  → indices 1,5,9,13
        let t1 = s[1]
        s[1] = s[5]
        s[5] = s[9]
        s[9] = s[13]
        s[13] = t1
        // Row 2: left by 2  → indices 2,6,10,14
        var t = s[2]
        s[2] = s[10]
        s[10] = t
        t = s[6]
        s[6] = s[14]
        s[14] = t
        // Row 3: left by 3  → indices 3,7,11,15 (equivalent to right by 1)
        let t3 = s[15]
        s[15] = s[11]
        s[11] = s[7]
        s[7] = s[3]
        s[3] = t3
    }

    @inline(__always) private static func mixColumns(_ s: inout [UInt8]) {
        for c in 0 ..< 4 {
            let s0 = s[c * 4], s1 = s[c * 4 + 1], s2 = s[c * 4 + 2], s3 = s[c * 4 + 3]
            s[c * 4 + 0] = gmul2(s0) ^ gmul3(s1) ^ s2 ^ s3
            s[c * 4 + 1] = s0 ^ gmul2(s1) ^ gmul3(s2) ^ s3
            s[c * 4 + 2] = s0 ^ s1 ^ gmul2(s2) ^ gmul3(s3)
            s[c * 4 + 3] = gmul3(s0) ^ s1 ^ s2 ^ gmul2(s3)
        }
    }

    // MARK: GF(2^8) arithmetic

    @inline(__always) private static func gmul2(_ x: UInt8) -> UInt8 {
        (x & 0x80) != 0 ? (x << 1) ^ 0x1B : x << 1
    }

    @inline(__always) private static func gmul3(_ x: UInt8) -> UInt8 { gmul2(x) ^ x }
}

// MARK: - AES S-Box (FIPS 197 Fig. 7)

private let sbox: [UInt8] = [
    0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76,
    0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0,
    0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15,
    0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75,
    0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0, 0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84,
    0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF,
    0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8,
    0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5, 0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2,
    0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73,
    0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB,
    0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C, 0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79,
    0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08,
    0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A,
    0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E, 0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E,
    0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF,
    0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16
]
