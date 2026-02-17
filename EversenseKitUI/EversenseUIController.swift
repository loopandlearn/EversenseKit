import LoopKitUI
import SwiftUI

enum EversenseUIScreen {
    case onboardingStart
    case onboardingAuth
    case onboardingScan

    case settings
    case transmitterSettings
    case placementGuide
    case calibration
    case calibrationHistory
    case alertHistory
}

class EversenseUIController: UINavigationController, CGMManagerOnboarding, CompletionNotifying, UINavigationControllerDelegate {
    let logger = EversenseLogger(category: "EversenseUIController")

    var cgmManagerOnboardingDelegate: LoopKitUI.CGMManagerOnboardingDelegate?
    var completionDelegate: LoopKitUI.CompletionDelegate?
    var cgmManager: EversenseCGMManager?
    var displayGlucosePreference: DisplayGlucosePreference

    var colorPalette: LoopUIColorPalette
    var screenStack = [EversenseUIScreen]()

    init(
        cgmManager: EversenseCGMManager? = nil,
        colorPalette: LoopUIColorPalette,
        displayGlucosePreference: DisplayGlucosePreference,
        allowDebugFeatures _: Bool
    )
    {
        if let cgmManager = cgmManager {
            self.cgmManager = cgmManager
        } else {
            self.cgmManager = EversenseCGMManager(rawState: [:])
        }
        self.colorPalette = colorPalette
        self.displayGlucosePreference = displayGlucosePreference
        super.init(navigationBarClass: UINavigationBar.self, toolbarClass: UIToolbar.self)
    }

    @available(*, unavailable) required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self

        navigationBar.prefersLargeTitles = true // Ensure nav bar text is displayed correctly

        if screenStack.isEmpty {
            let screen = getInitialScreen()
            let viewController = viewControllerForScreen(screen)

            screenStack = [screen]
            viewController.isModalInPresentation = false
            setViewControllers([viewController], animated: false)
        }
    }

    private func getInitialScreen() -> EversenseUIScreen {
        guard let cgmManager = cgmManager else {
            return .onboardingStart
        }

        return cgmManager.state.isOnboarded ? .settings : .onboardingStart
    }

    private func hostingController<Content: View>(rootView: Content) -> DismissibleHostingController<some View> {
        let rootView = rootView
            .environment(\.appName, Bundle.main.bundleDisplayName)
            .environmentObject(displayGlucosePreference)
        return DismissibleHostingController(content: rootView, colorPalette: colorPalette)
    }

    private func viewControllerForScreen(_ screen: EversenseUIScreen) -> UIViewController {
        switch screen {
        case .onboardingStart:
            let view = EversenseOnboardingStart(nextAction: onboardingNextStep)
            return hostingController(rootView: view)

        case .onboardingAuth:
            let viewModel = Eversense365AuthViewModel(cgmManager, { self.navigateTo(.onboardingScan) })
            return hostingController(rootView: Eversense365Auth(viewModel: viewModel))

        case .onboardingScan:
            let completion = {
                if let cgmManager = self.cgmManager {
                    cgmManager.state.isOnboarded = true
                    cgmManager.notifyStateDidChange()

                    if let cgmManagerOnboardingDelegate = self.cgmManagerOnboardingDelegate {
                        DispatchQueue.main.async {
                            cgmManagerOnboardingDelegate.cgmManagerOnboarding(didOnboardCGMManager: cgmManager)
                            cgmManagerOnboardingDelegate.cgmManagerOnboarding(didCreateCGMManager: cgmManager)
                            self.completionDelegate?.completionNotifyingDidComplete(self)
                        }
                    } else {
                        self.logger.warning("Not onboarded -> no onboardDelegate...")
                        DispatchQueue.main.async {
                            self.completionDelegate?.completionNotifyingDidComplete(self)
                        }
                    }
                }
            }

            let viewModel = EversenseScanViewModel(cgmManager, completion)
            return hostingController(rootView: Eversense365ScanView(viewModel: viewModel))

        case .settings:
            let deleteCgm = {
                guard let cgmManager = self.cgmManager else {
                    return
                }

                cgmManager.delete {
                    DispatchQueue.main.async {
                        self.completionDelegate?.completionNotifyingDidComplete(self)
                    }
                }
            }
            let toTransmitterSettings = {
                self.navigateTo(.transmitterSettings)
            }
            let toPlacementGuide = {
                self.navigateTo(.placementGuide)
            }
            let toCalibration = {
                self.navigateTo(.calibration)
            }
            let toCalibrationHistory = {
                self.navigateTo(.calibrationHistory)
            }
            let toAlertHistory = {
                self.navigateTo(.alertHistory)
            }

            let viewModel = EversenseSettingsViewModel(
                cgmManager: cgmManager,
                deleteCgm: deleteCgm,
                toTransmitterSettings: toTransmitterSettings,
                toPlacementGuide: toPlacementGuide,
                toCalibration: toCalibration,
                toCalibrationHistory: toCalibrationHistory,
                toAlertHistory: toAlertHistory
            )
            return hostingController(rootView: EversenseSettingsView(viewModel: viewModel))
        case .transmitterSettings:
            let viewModel = TransmitterSettingsViewModel(cgmManager: cgmManager, unit: displayGlucosePreference.unit)
            return hostingController(rootView: TransmitterSettingsView(viewModel: viewModel))
        case .placementGuide:
            if #available(iOS 16.0, *) {
                let viewModel = PlacementGuideViewModel(cgmManager: cgmManager)
                return hostingController(rootView: PlacementGuideView(viewModel: viewModel))
            } else {
                return hostingController(rootView: PlacementGuideEmpty())
            }
        case .calibration:
            let viewModel = CalibrationViewModel(cgmManager: cgmManager, displayGlucosePreference.unit, goBack)
            return hostingController(rootView: CalibrationView(viewModel: viewModel))
        case .calibrationHistory:
            let viewModel = CalibrationHistoryViewModel(cgmManager: cgmManager, glucosePreference: displayGlucosePreference)
            return hostingController(rootView: CalibrationHistoryView(viewModel: viewModel))
        case .alertHistory:
            let viewModel = AlertHistoryViewModel(cgmManager: cgmManager)
            return hostingController(rootView: AlertHistoryView(viewModel: viewModel))
        }
    }

    private func navigateTo(_ screen: EversenseUIScreen) {
        screenStack.append(screen)
        let viewController = viewControllerForScreen(screen)
        viewController.isModalInPresentation = false
        pushViewController(viewController, animated: true)
        viewController.view.layoutSubviews()
    }

    private func goBack() {
        guard screenStack.count > 1 else {
            return
        }

        _ = screenStack.popLast()
        popViewController(animated: true)
    }

    private func onboardingNextStep(_ cgmType: Int) {
        #if targetEnvironment(simulator)
            if let cgmManager = self.cgmManager {
                cgmManager.state.isOnboarded = true
                cgmManager.state.bleNameString = "Eversense 365 DEMO"
                cgmManager.state.security = .v2 // Eversense 365
                cgmManager.state.recentGlucoseInMgDl = 140
                cgmManager.state.recentGlucoseDateTime = Date.now
                cgmManager.state.recentGlucoseTrend = .flat
                cgmManager.state.signalStrength = .Good
                cgmManager.state.signalStrengthRaw = 1350
                cgmManager.state.batteryPercentage = 75
                cgmManager.state.calibrationMode = .WeeklySingle
                cgmManager.state.calibrationPhase = .DAILY_CALIBRATION
                cgmManager.state.calibrationReadiness = .Ready
                cgmManager.state.activatedAt = Date.now
                cgmManager.state.lastCalibration = Date.now
                cgmManager.state.nextCalibration = Date.now.addingTimeInterval(TimeInterval(days: 7))
                cgmManager.state.lastSynced = Date.now
                cgmManager.state.activeAlarms = [
                    ActiveAlarm(code: .CalibrationNowAlarm, codeRaw: Alarm.CalibrationNowAlarm.rawValue, flag: 0, priority: 0),
                    ActiveAlarm(code: .BatteryOptimization, codeRaw: Alarm.BatteryOptimization.rawValue, flag: 0, priority: 1),
                    ActiveAlarm(code: .PredictiveHighAlarm, codeRaw: Alarm.CalibrationNowAlarm.rawValue, flag: 0, priority: 2)
                ]

                if let cgmManagerOnboardingDelegate = self.cgmManagerOnboardingDelegate {
                    DispatchQueue.main.async {
                        cgmManagerOnboardingDelegate.cgmManagerOnboarding(didOnboardCGMManager: cgmManager)
                        cgmManagerOnboardingDelegate.cgmManagerOnboarding(didCreateCGMManager: cgmManager)
                        self.completionDelegate?.completionNotifyingDidComplete(self)
                    }
                }
            }
        #else
            switch cgmType {
            case 0:
                // Eversense E3
                navigateTo(.onboardingScan)
                return

            case 1:
                // Eversense 365
                navigateTo(.onboardingAuth)
                return
            default:
                logger.error("Invalid transmitter type received: \(cgmType)")
            }
        #endif
    }
}
