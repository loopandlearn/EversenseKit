import SwiftUI

struct TransmitterInfoView: View {
    @ObservedObject var viewModel: TransmitterInfoViewModel

    var body: some View {
        List {
            Section {
                SectionItem(
                    title: Text("Transmitter name", comment: "name"),
                    value: viewModel.transmitterName
                )
                SectionItem(
                    title: Text("Current phase", comment: "current phase"),
                    value: viewModel.currentPhase
                )
                SectionItem(
                    title: Text("Signal strength", comment: "transmitter implant signal strength"),
                    value: viewModel.signalStrength
                )
                SectionItem(
                    title: Text("Battery percentage", comment: "transmitter battery level"),
                    value: viewModel.batteryLevel
                )
                HStack {
                    Text("Insertion date", comment: "insertiondate")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(viewModel.insertionDate)
                            .foregroundColor(.secondary)

                        Text(viewModel.insertionTime)
                            .foregroundColor(.secondary)
                    }
                }
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
