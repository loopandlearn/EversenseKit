import Charts
import SwiftUI

@available(iOS 16.0, *) struct PlacementGuideView: View {
    @ObservedObject var viewModel: PlacementGuideViewModel

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center) {
                Text(
                    LocalizedString("Signal strength", comment: "transmitter implant signal strength") + ": " + viewModel
                        .strength.title
                )
                .font(.headline)

                Text(LocalizedString("Last update: ", comment: "label for last update") + viewModel.lastUpdate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 50)

                Chart {
                    BarMark(
                        y: .value("", viewModel.strengthRaw)
                    )
                }
                .foregroundStyle(.blue)
                .chartYScale(domain: [0, 100])
                .chartYAxis {
                    AxisMarks(values: [0, 25, 50, 75, 100])
                }
                .frame(width: 150, height: 400)
            }
        }
        .navigationBarTitle(LocalizedString("Placement Guide", comment: "Title for placement guide"))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.stop()
        }
    }
}

// Used for iOS 15 or lower
struct PlacementGuideEmpty: View {
    var body: some View {
        VStack {}
            .navigationBarTitle(LocalizedString("Placement Guide", comment: "Title for placement guide"))
    }
}
