import LoopKitUI
import SwiftUI

struct CalibrationHistoryView: View {
    @ObservedObject var viewModel: CalibrationHistoryViewModel

    var body: some View {
        VStack(alignment: .center) {
            if viewModel.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
                Text("Loading data...", comment: "loading calibration data")
            } else {
                List {
                    ForEach($viewModel.history.reversed()) { group in
                        Section(header: Text(group.wrappedValue.date)) {
                            ForEach(group.items.reversed()) { item in
                                HStack {
                                    Text(item.wrappedValue.glucose)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(item.wrappedValue.flag.getTitle())
                                        Text(item.wrappedValue.time)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.start()
        }
    }
}
