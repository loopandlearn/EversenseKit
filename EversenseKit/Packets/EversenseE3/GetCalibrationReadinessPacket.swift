extension EversenseE3 {
    class GetCalibrationReadinessResponse {
        public let calibrationReadiness: CalibrationReadiness

        init(calibrationReadiness: CalibrationReadiness) {
            self.calibrationReadiness = calibrationReadiness
        }
    }

    class GetCalibrationReadinessPacket: BasePacket {
        typealias T = GetCalibrationReadinessResponse

        var responseType: UInt8 {
            PacketIds.readSingleByteSerialFlashRegisterResponseId.rawValue
        }

        var responseId: UInt8? {
            nil
        }

        func getRequestData() -> Data {
            CommandOperations.readSingleByteSerialFlashRegister(memoryAddress: FlashMemory.calibrationReadiness)
        }

        func parseResponse(data: Data) -> GetCalibrationReadinessResponse {
            GetCalibrationReadinessResponse(
                calibrationReadiness: CalibrationReadiness(rawValue: data[start]) ?? .Unknown
            )
        }
    }
}
