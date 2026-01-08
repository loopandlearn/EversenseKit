import LoopKitUI
import SwiftUI

struct AlertHistoryView: View {
    @ObservedObject var viewModel: AlertHistoryViewModel

    var body: some View {
        NavigationView {
            if viewModel.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
                Text(LocalizedString("Loading data...", comment: "loading calibration data"))
            } else {
                List {
                    ForEach($viewModel.history.reversed()) { group in
                        Section(header: Text(group.wrappedValue.date)) {
                            ForEach(group.items.reversed()) { item in
                                HStack {
                                    Text(item.wrappedValue.alarmTitle)
                                    Spacer()
                                    Text(item.wrappedValue.time)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(LocalizedString("Alert history", comment: "Alert history header"))
        .onAppear {
            viewModel.start()
        }
    }

    private func groupByDate(_: Date) {}
}
