import LoopKitUI
import SwiftUI

struct EversenseSettingsView: View {
    @Environment(\.dismissAction) private var dismiss
    @Environment(\.guidanceColors) private var guidanceColors
    @EnvironmentObject private var displayGlucosePreference: DisplayGlucosePreference

    @ObservedObject var viewModel: EversenseSettingsViewModel
    @State private var isSharePresented: Bool = false

    var removeCgmManagerActionSheet: ActionSheet {
        ActionSheet(
            title: Text("Remove CGM", comment: "Label for CgmManager deletion button"),
            message: Text(
                "Are you sure you want to stop using Eversense CGM?",
                comment: "Message for CgmManager deletion action sheet"
            ),
            buttons: [
                .destructive(
                    Text("Confirm", comment: "Confirmation label")
                ) {
                    viewModel.deleteCgm()
                },
                .cancel()
            ]
        )
    }

    var body: some View {
        List {
            Section {
                VStack {
                    HStack {
                        Spacer()
                        Image(uiImage: UIImage(
                            named: viewModel.is365 ? "transmitter365" : "transmitter",
                            in: Bundle(for: EversenseUIController.self),
                            compatibleWith: nil
                        )!)
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal)
                            .frame(height: 150)
                        Spacer()
                    }

                    HStack(alignment: .bottom) {
                        Text("Next calibration in", comment: "Calibration hint")
                            .foregroundColor(.secondary)
                        Spacer()
                        calibarationTimer
                    }

                    ProgressView(value: viewModel.nextCalibrationProcess)
                        .scaleEffect(x: 1, y: 4, anchor: .center)
                        .padding(.top, 2)
                        .tint(viewModel.nextCalibrationProcessColor)
                }

                HStack(alignment: .top) {
                    transmitterState
                    Spacer()
                    transmitterBattery
                }
                .padding(.bottom, 5)

                ForEach(viewModel.activeAlarm) { item in
                    TransmitterAlarm(activeAlarm: item)
                }
            }

            Section {
                SectionItem(
                    title: Text("Glucose", comment: "last reading"),
                    value: displayGlucosePreference.format(viewModel.lastMeasurement)
                )
                SectionItem(
                    title: Text("Time", comment: "last reading"),
                    value: viewModel.lastMeasurementDatetime
                )
            } header: {
                Text("Recent glucose", comment: "last reading")
            }

            Section {
                HStack {
                    Text("Last calibration time", comment: "last calibration")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(viewModel.lastCalibrationDate)
                            .foregroundColor(.secondary)

                        Text(viewModel.lastCalibrationTime)
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Text("Next calibration time", comment: "last calibration")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(viewModel.nextCalibrationDate)
                            .foregroundColor(.secondary)

                        Text(viewModel.nextCalibrationTime)
                            .foregroundColor(.secondary)
                    }
                }
                if viewModel.allowCalibrations {
                    Button(action: { viewModel.toCalibration() }) {
                        HStack {
                            Text("Calibrate transmitter", comment: "calibration")
                            Spacer()
                            if viewModel.calibrationReadiness != .Ready {
                                Text(viewModel.calibrationReadiness.description)
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: UIFont.systemFontSize, weight: .medium))
                                    .opacity(0.35)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(viewModel.calibrationReadiness != .Ready)
                }
                Button(action: { viewModel.toCalibrationHistory() }) {
                    HStack {
                        Text("Calibration history", comment: "calibration")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: UIFont.systemFontSize, weight: .medium))
                            .opacity(0.35)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text("Calibrations", comment: "calibration section")
            }

            Section {
                Button(action: viewModel.toTransmitterInfo) {
                    HStack {
                        Text("Transmitter information", comment: "go to transmitter info")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: UIFont.systemFontSize, weight: .medium))
                            .opacity(0.35)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: viewModel.toTransmitterSettings) {
                    HStack {
                        Text("Transmitter settings", comment: "go to transmitter settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: UIFont.systemFontSize, weight: .medium))
                            .opacity(0.35)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: viewModel.toDMSSettings) {
                    HStack {
                        Text("DMS Settings", comment: "go to eversense dms settings")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: UIFont.systemFontSize, weight: .medium))
                            .opacity(0.35)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { viewModel.toAlertHistory() }) {
                    HStack {
                        Text("Alert history", comment: "alerts")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: UIFont.systemFontSize, weight: .medium))
                            .opacity(0.35)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())

                if #available(iOS 16.0, *) {
                    Button(action: viewModel.toPlacementGuide) {
                        HStack {
                            Text("Placement Guide", comment: "Title for placement guide")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: UIFont.systemFontSize, weight: .medium))
                                .opacity(0.35)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } header: {
                Text("Transmitter Settings", comment: "transmitter section")
            }

            Section {
                SectionItem(
                    title: Text("Last sync", comment: "transmitter last sync"),
                    value: viewModel.lastSync
                )

                Button(action: { self.isSharePresented = true }) {
                    Text("Share Eversense logs", comment: "share logs")
                }
                .sheet(isPresented: $isSharePresented, onDismiss: {}, content: {
                    ActivityViewController(activityItems: viewModel.getLogs())
                })

                Button(action: viewModel.readGlucose) {
                    HStack {
                        Text("Force sync", comment: "force transmitter sync")
                        Spacer()
                        if viewModel.forceSyncing {
                            ActivityIndicator(isAnimating: .constant(true), style: .medium)
                        }
                    }
                }
                .disabled(viewModel.forceSyncing)

                Button(action: {
                    viewModel.showingDeleteConfirmation = true
                }) {
                    Text("Delete CGM", comment: "Label for CgmManager deletion button")
                        .foregroundColor(guidanceColors.critical)
                }
                .actionSheet(isPresented: $viewModel.showingDeleteConfirmation) {
                    removeCgmManagerActionSheet
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: Button(action: dismiss) {
            Text("Done", comment: "done button title")
        })
    }

    @ViewBuilder private var transmitterState: some View {
        VStack(alignment: .leading) {
            Text("State", comment: "Transmitter state")
                .foregroundColor(Color(UIColor.secondaryLabel))
            Text(viewModel.connectionStatus)
                .font(.title3)
                .fontWeight(.heavy)
                .fixedSize()
        }
    }

    @ViewBuilder private var transmitterBattery: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("Battery", comment: "Transmitter name")
                .foregroundColor(Color(UIColor.secondaryLabel))
            HStack(alignment: .center, spacing: 5) {
                BatteryView(batteryLevel: viewModel.batteryPercentage)
                    .frame(width: 35, height: 16)

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(viewModel.batteryLevel)
                        .font(.title3)
                        .fontWeight(.heavy)
                        .fixedSize()

                    if viewModel.batteryPercentage <= 1 {
                        Text(String("%"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder private var calibarationTimer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if viewModel.nextCalibrationDays > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.0f", viewModel.nextCalibrationDays))
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text("d", comment: "day")
                        .foregroundColor(.secondary)
                }
            }
            if viewModel.nextCalibrationHours > 0 {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.0f", viewModel.nextCalibrationHours))
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text("h", comment: "hour")
                        .foregroundColor(.secondary)
                }
            }
            if viewModel.nextCalibrationDays == 0 {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.0f", viewModel.nextCalibrationMinutes))
                        .font(.system(size: 28))
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                    Text("min", comment: "minute")
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder private func TransmitterAlarm(activeAlarm: ActiveAlarmItem) -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 5) {
                switch activeAlarm.code.type {
                case .Info:
                    Image(systemName: "info.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.blue)
                case .Warning:
                    Image(systemName: "exclamationmark.octagon.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                case .Critical:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                }

                HStack(spacing: 5) {
                    Text(activeAlarm.code.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if activeAlarm.code == .unknown {
                        Text(String(format: "%d", activeAlarm.codeRaw))
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.bottom, 5)

            if let description = activeAlarm.code.description {
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func SectionItem(title: Text, value: String) -> some View {
        HStack(alignment: .bottom) {
            title
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
