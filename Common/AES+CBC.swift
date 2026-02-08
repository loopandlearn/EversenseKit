import CommonCrypto
import CryptoKit
import Foundation

enum AESCBCError: Error {
    case invalidKeyLength
    case invalidIVLength
    case cryptOperationFailed(status: CCCryptorStatus)
}

extension AES {
    enum CBC {
        static func encrypt(key: SymmetricKey, data: Data, iv: Data) throws -> Data {
            try crypt(
                data: data,
                key: key,
                iv: iv,
                operation: CCOperation(kCCEncrypt)
            )
        }

        static func decrypt(key: SymmetricKey, data: Data, iv: Data) throws -> Data {
            try crypt(
                data: data,
                key: key,
                iv: iv,
                operation: CCOperation(kCCDecrypt)
            )
        }

        private static func crypt(
            data: Data,
            key: SymmetricKey,
            iv: Data,
            operation: CCOperation
        ) throws -> Data {
            var outLength = 0
            var buffer = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)

            let status = data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    iv.withUnsafeBytes { ivBytes in

                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress,
                            keyBytes.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress,
                            data.count,
                            &buffer,
                            buffer.count,
                            &outLength
                        )
                    }
                }
            }

            guard status == kCCSuccess else {
                throw AESCBCError.cryptOperationFailed(status: status)
            }

            return Data(buffer.prefix(outLength))
        }
    }
}
