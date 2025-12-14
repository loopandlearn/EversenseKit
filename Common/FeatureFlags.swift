enum FeatureFlags {
    public static let ALLOW_CALIBRATION = Bundle(for: EversenseCGMManager.self)
        .object(forInfoDictionaryKey: "EVERSENSE_ALLOW_CALIBRATIONS") as? Bool ?? false
}
