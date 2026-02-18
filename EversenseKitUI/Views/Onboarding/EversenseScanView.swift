import LoopKitUI
import SwiftUI

struct Eversense365ScanView: View {
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismissAction) private var dismiss

    @ObservedObject var viewModel: EversenseScanViewModel

    var body: some View {
        VStack {
            List {
                Section {
                    Text(LocalizedString(
                        "Make sure your Eversense is in pairing mode. Please read the manual to learn how to do this.",
                        comment: "Scanning hint"
                    ))

                    if !viewModel.error.isEmpty {
                        Text(viewModel.error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    content
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarHidden(false)
        .navigationTitle(LocalizedString("Scanning", comment: "Scanning header"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizedString("Cancel", comment: "Cancel button title"), action: {
                    self.dismiss()
                })
            }
        }
        .onChange(of: isPresented) { newValue in
            if !newValue {
                viewModel.stopScan()
            }
        }
    }

    @ViewBuilder private var content: some View {
        ForEach($viewModel.results) { $result in
            Button(action: { viewModel.connect($result.wrappedValue) }) {
                HStack {
                    Text($result.name.wrappedValue)
                    Spacer()
                    if viewModel.connectingTo.isEmpty {
                        Image(systemName: "chevron.right")
                            .font(.system(size: UIFont.systemFontSize, weight: .medium))
                            .opacity(0.35)
                    } else if $result.name.wrappedValue == viewModel.connectingTo {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    }
                }
                .padding(.horizontal)
            }
            .disabled(!viewModel.connectingTo.isEmpty)
            .buttonStyle(.plain)
        }
    }
}
