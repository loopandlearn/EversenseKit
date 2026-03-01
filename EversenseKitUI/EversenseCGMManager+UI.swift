import LoopKit
import LoopKitUI

extension EversenseCGMManager: CGMManagerUI {
    public static func setupViewController(
        bluetoothProvider _: BluetoothProvider,
        displayGlucosePreference: DisplayGlucosePreference,
        colorPalette: LoopUIColorPalette,
        allowDebugFeatures: Bool,
        prefersToSkipUserInteraction _: Bool = false
    ) -> SetupUIResult<CGMManagerViewController, CGMManagerUI> {
        let vc = EversenseUIController(
            colorPalette: colorPalette,
            displayGlucosePreference: displayGlucosePreference,
            allowDebugFeatures: allowDebugFeatures
        )
        return .userInteractionRequired(vc)
    }

    public func settingsViewController(
        bluetoothProvider _: BluetoothProvider,
        displayGlucosePreference: DisplayGlucosePreference,
        colorPalette: LoopUIColorPalette,
        allowDebugFeatures: Bool
    ) -> CGMManagerViewController {
        EversenseUIController(
            cgmManager: self,
            colorPalette: colorPalette,
            displayGlucosePreference: displayGlucosePreference,
            allowDebugFeatures: allowDebugFeatures
        )
    }

    public static var onboardingImage: UIImage? {
        UIImage(
            named: "transmitter",
            in: Bundle(for: EversenseUIController.self),
            compatibleWith: nil
        )
    }

    public var smallImage: UIImage? {
        UIImage(
            named: state.is365 ? "transmitter365" : "transmitter",
            in: Bundle(for: EversenseUIController.self),
            compatibleWith: nil
        )
    }

    public var cgmStatusHighlight: (any LoopKit.DeviceStatusHighlight)? {
        nil
    }

    public var cgmLifecycleProgress: (any LoopKit.DeviceLifecycleProgress)? {
        if let nextCalibration = state.nextCalibration, nextCalibration.addingTimeInterval(.days(-1)) >= Date.now {
            return EversenseLifecycleProgress(
                percentComplete: 1 - max((nextCalibration.timeIntervalSinceNow / .days(1)), 0),
                progressState: nextCalibration >= Date.now ? .critical : .warning
            )
        }

        return nil
    }

    public var cgmStatusBadge: (any LoopKitUI.DeviceStatusBadge)? {
        if state.activeAlarms.contains(where: { Alarm.criticalAlarms.contains($0.code) }) {
            return EversenseDeviceStatusBadge(image: UIImage(systemName: "exclamationmark.triangle"), state: .critical)
        }

        if state.activeAlarms.contains(where: { Alarm.warningAlarms.contains($0.code) }) {
            return EversenseDeviceStatusBadge(image: UIImage(systemName: "clock"), state: .warning)
        }

        return nil
    }
}

struct EversenseDeviceStatusBadge: DeviceStatusBadge {
    var image: UIImage?
    var state: LoopKitUI.DeviceStatusBadgeState
}

struct EversenseLifecycleProgress: DeviceLifecycleProgress {
    var percentComplete: Double
    var progressState: LoopKit.DeviceLifecycleProgressState
}
