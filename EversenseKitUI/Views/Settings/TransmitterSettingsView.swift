import LoopKitUI
import SwiftUI

struct TransmitterSettingsView: View {
    @State var pickerRateRising = false
    @State var pickerRateFalling = false
    @State var pickerPredictionHighTime = false
    @State var pickerPredictionHighThreshold = false
    @State var pickerPredictionLowTime = false
    @State var pickerPredictionLowThreshold = false
    @State var pickerGlucoseHigh = false
    @State var pickerGlucoseLow = false

    @EnvironmentObject private var displayGlucosePreference: DisplayGlucosePreference
    @ObservedObject var viewModel: TransmitterSettingsViewModel

    func timeFormatter(_ time: TimeInterval) -> String {
        String(format: "%.0f", time.minutes) + " " + LocalizedString("min", comment: "minute")
    }

    var body: some View {
        VStack {
            List {
                toggleRow(
                    label: LocalizedString("Enable transmitter vibration", comment: "label vibration mode"),
                    hint: LocalizedString(
                        "Disable this value if you wish to not receive any alerts from your transmitter",
                        comment: "hint vibration mode"
                    ),
                    value: $viewModel.vibrationMode
                )

                valueRow(
                    labelValue: LocalizedString("Glucose low", comment: "label glucose low"),
                    hint: LocalizedString(
                        "Configure when to receive an alert for low glucose",
                        comment: "hint glucose low"
                    ),
                    statePicker: $pickerGlucoseLow,
                    valueValue: $viewModel.glucoseLowInMgDl,
                    allowedOptions: viewModel.glucoseLowAllowedOptions
                )

                toggleValueRow(
                    labelToggle: LocalizedString("Enable high glucose alerts", comment: "label toggle glucose high alert"),
                    labelValue: LocalizedString("Glucose high", comment: "label glucose high"),
                    hint: LocalizedString(
                        "Enable this value if you wish to receive alerts from your transmitter if you exceed a high glucose",
                        comment: "hint glucose high"
                    ),
                    statePicker: $pickerGlucoseHigh,
                    valueToggle: $viewModel.enableGlucoseHighAlerts,
                    valueValue: $viewModel.glucoseHighInMgDl,
                    allowedOptions: viewModel.glucoseHighAllowedOptions
                )

                toggleValueRateRow(
                    labelToggle: LocalizedString("Rising alarming enabled", comment: "label rising alarming enabled"),
                    labelValue: LocalizedString("Rate change", comment: "label alarming rate change"),
                    hint: LocalizedString(
                        "The transmitter can alarm you if you are rising too fast",
                        comment: "hint rising alarming"
                    ),
                    statePicker: $pickerRateRising,
                    valueToggle: $viewModel.rateRisingEnabled,
                    valueValue: $viewModel.rateRisingThreshold,
                    allowedOptions: viewModel.rateAllowedOptions
                )

                toggleValueRateRow(
                    labelToggle: LocalizedString("Falling alarming enabled", comment: "label falling alarming enabled"),
                    labelValue: LocalizedString("Rate change", comment: "label alarming rate change"),
                    hint: LocalizedString(
                        "The transmitter can alarm you if you are falling too fast",
                        comment: "hint falling alarming"
                    ),
                    statePicker: $pickerRateFalling,
                    valueToggle: $viewModel.rateFallingEnabled,
                    valueValue: $viewModel.rateFallingThreshold,
                    allowedOptions: viewModel.rateAllowedOptions
                )

                togglePredictionRow(
                    labelToggle: LocalizedString(
                        "Prediction high alarming enabled",
                        comment: "label prediction high alarming enabled"
                    ),
                    labelTime: LocalizedString("Prediction period", comment: "label prediction period"),
                    labelThreshold: LocalizedString("Prediction target", comment: "label prediction target"),
                    hint: LocalizedString(
                        "The transmitter can alarm you if it predictions you are rising above the threshold",
                        comment: "hint rising prediction"
                    ),
                    stateTimePicker: $pickerPredictionHighTime,
                    stateThresholdPicker: $pickerPredictionHighThreshold,
                    valueToggle: $viewModel.predictionHighEnabled,
                    valueTime: $viewModel.predictionHighTime,
                    valueThreshold: $viewModel.predictionHighThreshold,
                    allowedTimeOptions: viewModel.timeAllowedOptions,
                    allowedThresholdOptions: viewModel.glucoseHighAllowedOptions
                )

                togglePredictionRow(
                    labelToggle: LocalizedString(
                        "Prediction Low alarming enabled",
                        comment: "label prediction high alarming enabled"
                    ),
                    labelTime: LocalizedString("Prediction period", comment: "label prediction period"),
                    labelThreshold: LocalizedString("Prediction target", comment: "label prediction target"),
                    hint: LocalizedString(
                        "The transmitter can alarm you if it predictions you are falling below the threshold",
                        comment: "hint falling prediction"
                    ),
                    stateTimePicker: $pickerPredictionLowTime,
                    stateThresholdPicker: $pickerPredictionLowThreshold,
                    valueToggle: $viewModel.predictionLowEnabled,
                    valueTime: $viewModel.predictionLowTime,
                    valueThreshold: $viewModel.predictionLowThreshold,
                    allowedTimeOptions: viewModel.timeAllowedOptions,
                    allowedThresholdOptions: viewModel.glucoseLowAllowedOptions
                )
            }

            Spacer()

            if !viewModel.error.isEmpty {
                Text(viewModel.error)
                    .foregroundStyle(.red)
            }

            Button(action: viewModel.saveSettings) {
                if viewModel.loading {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    Text(LocalizedString("Continue", comment: "Text for continue button"))
                }
            }
            .buttonStyle(ActionButtonStyle())
            .padding([.bottom, .horizontal])
            .disabled(viewModel.loading)
        }
        .navigationBarTitle(LocalizedString("Transmitter settings", comment: "Title for user options"))
    }

    @ViewBuilder private func toggleRow(label: String, hint: String, value: Binding<Bool>) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 20) {
                Toggle(isOn: value) {
                    Text(label)
                }
            }
        } footer: {
            Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func toggleValueRateRow(
        labelToggle: String,
        labelValue: String,
        hint: String,
        statePicker: Binding<Bool>,
        valueToggle: Binding<Bool>,
        valueValue: Binding<Double>,
        allowedOptions: [Double]
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 20) {
                Toggle(isOn: valueToggle) {
                    Text(labelToggle)
                }

                if valueToggle.wrappedValue {
                    HStack {
                        Text(labelValue)
                            .foregroundStyle(statePicker.wrappedValue ? .blue : .primary)
                        Spacer()
                        Text(viewModel.toRateFormatted(valueValue.wrappedValue))
                            .foregroundStyle(statePicker.wrappedValue ? .blue : .secondary)
                    }
                    .onTapGesture {
                        statePicker.wrappedValue.toggle()
                    }

                    if statePicker.wrappedValue {
                        ResizeablePicker(
                            selection: valueValue,
                            data: allowedOptions,
                            formatter: { viewModel.toRateFormatted($0) }
                        )
                    }
                }
            }
        } footer: {
            Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func toggleValueRow(
        labelToggle: String,
        labelValue: String,
        hint: String,
        statePicker: Binding<Bool>,
        valueToggle: Binding<Bool>,
        valueValue: Binding<Double>,
        allowedOptions: [Double]
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 20) {
                Toggle(isOn: valueToggle) {
                    Text(labelToggle)
                }

                if valueToggle.wrappedValue {
                    HStack {
                        Text(labelValue)
                            .foregroundStyle(statePicker.wrappedValue ? .blue : .primary)
                        Spacer()
                        Text(displayGlucosePreference.format(viewModel.toHkQuantity(valueValue.wrappedValue)))
                            .foregroundStyle(statePicker.wrappedValue ? .blue : .secondary)
                    }
                    .onTapGesture {
                        statePicker.wrappedValue.toggle()
                    }

                    if statePicker.wrappedValue {
                        ResizeablePicker(
                            selection: valueValue,
                            data: allowedOptions,
                            formatter: { displayGlucosePreference.format(viewModel.toHkQuantity($0)) }
                        )
                    }
                }
            }
        } footer: {
            Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func togglePredictionRow(
        labelToggle: String,
        labelTime: String,
        labelThreshold: String,
        hint: String,
        stateTimePicker: Binding<Bool>,
        stateThresholdPicker: Binding<Bool>,
        valueToggle: Binding<Bool>,
        valueTime: Binding<TimeInterval>,
        valueThreshold: Binding<Double>,
        allowedTimeOptions: [TimeInterval],
        allowedThresholdOptions: [Double]
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 20) {
                Toggle(isOn: valueToggle) {
                    Text(labelToggle)
                }

                if valueToggle.wrappedValue {
                    HStack {
                        Text(labelTime)
                            .foregroundStyle(stateTimePicker.wrappedValue ? .blue : .primary)
                        Spacer()
                        Text(timeFormatter(valueTime.wrappedValue))
                            .foregroundStyle(stateTimePicker.wrappedValue ? .blue : .secondary)
                    }
                    .onTapGesture {
                        stateTimePicker.wrappedValue.toggle()
                    }

                    if stateTimePicker.wrappedValue {
                        ResizeablePicker(
                            selection: valueTime,
                            data: allowedTimeOptions,
                            formatter: { timeFormatter($0) }
                        )
                    }

                    HStack {
                        Text(labelThreshold)
                            .foregroundStyle(stateThresholdPicker.wrappedValue ? .blue : .primary)
                        Spacer()
                        Text(displayGlucosePreference.format(viewModel.toHkQuantity(valueThreshold.wrappedValue)))
                            .foregroundStyle(stateThresholdPicker.wrappedValue ? .blue : .secondary)
                    }
                    .onTapGesture {
                        stateThresholdPicker.wrappedValue.toggle()
                    }

                    if stateThresholdPicker.wrappedValue {
                        ResizeablePicker(
                            selection: valueThreshold,
                            data: allowedThresholdOptions,
                            formatter: { displayGlucosePreference.format(viewModel.toHkQuantity($0)) }
                        )
                    }
                }
            }
        } footer: {
            Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private func valueRow(
        labelValue: String,
        hint: String,
        statePicker: Binding<Bool>,
        valueValue: Binding<Double>,
        allowedOptions: [Double]
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(labelValue)
                        .foregroundStyle(statePicker.wrappedValue ? .blue : .primary)
                    Spacer()
                    Text(displayGlucosePreference.format(viewModel.toHkQuantity(valueValue.wrappedValue)))
                        .foregroundStyle(statePicker.wrappedValue ? .blue : .secondary)
                }
                .onTapGesture {
                    statePicker.wrappedValue.toggle()
                }

                if statePicker.wrappedValue {
                    ResizeablePicker(
                        selection: valueValue,
                        data: allowedOptions,
                        formatter: { displayGlucosePreference.format(viewModel.toHkQuantity($0)) }
                    )
                }
            }
        } footer: {
            Text(hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
