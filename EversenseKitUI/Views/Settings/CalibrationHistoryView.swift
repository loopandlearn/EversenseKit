import LoopKitUI
import SwiftUI

struct CalibrationHistoryView: View {
    @ObservedObject var viewModel: CalibrationHistoryViewModel

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
                Text(LocalizedString("Loading data...", comment: "loading calibration data"))
            } else {
                List {}
            }
        }
        .navigationTitle(LocalizedString("Calibration history", comment: "Calibation history header"))
        .onAppear {
            viewModel.start()
        }
    }
}
