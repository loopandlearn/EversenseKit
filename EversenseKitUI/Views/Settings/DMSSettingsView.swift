import LoopKitUI
import SwiftUI

struct DMSSettingsView: View {
    @ObservedObject var viewModel: DMSSettingsViewModel
    @State var edittingBatchSize: Bool = false

    var body: some View {
        VStack {
            List {
                Section {
                    Toggle(isOn: $viewModel.enabled) {
                        Text("Allow upload to Eversense DMS", comment: "toggle enable DMS")
                    }

                    if viewModel.enabled {
                        HStack {
                            Text("Email Address", comment: "Label for email address")
                            TextField("", text: $viewModel.username)
                                .textContentType(.emailAddress)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("Password", comment: "Label for password")
                            SecureField("", text: $viewModel.password)
                                .textContentType(.emailAddress)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("Upload Delay", comment: "DMS batching label")
                                .foregroundStyle(edittingBatchSize ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                            Spacer()
                            Text(formatBatchSize(viewModel.batchSize))
                                .foregroundStyle(edittingBatchSize ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        }
                        .onTapGesture {
                            withAnimation {
                                edittingBatchSize.toggle()
                            }
                        }

                        if edittingBatchSize {
                            ResizeablePicker(
                                selection: $viewModel.batchSize,
                                data: viewModel.batchSizeOptions,
                                formatter: { formatBatchSize($0) }
                            )
                        }
                    }
                } footer: {
                    Text(
                        "Increasing the Upload Delay will lower the Internet usage, but gives the Eversense DMS a small delay",
                        comment: "batch size hint"
                    )
                }

                if viewModel.enabled {
                    Section {
                        HStack {
                            Label("Invite person", systemImage: "plus")
                                .foregroundStyle(.tint)
                        }
                        .onTapGesture {
                            edittingBatchSize.toggle()
                        }
                    } header: {
                        Text("Eversense NOW", comment: "Eversense NOW section")
                    }
                }
            }

            Spacer()
            if !viewModel.error.isEmpty {
                Text(viewModel.error)
                    .foregroundStyle(.red)
            }
            Button(action: viewModel.save) {
                if viewModel.isLoading {
                    ActivityIndicator(isAnimating: .constant(true), style: .medium)
                } else {
                    Text("Save", comment: "label save")
                }
            }
            .buttonStyle(ActionButtonStyle())
            .padding([.bottom, .horizontal])
            .disabled(viewModel.isLoading)
        }
        .navigationTitle(String(localized: "DMS Settings", comment: "DMS header"))
    }

    func formatBatchSize(_ size: Int) -> String {
        switch size {
        case 1: return String(localized: "None", comment: "Batch size - directly")
        case 3: return String(localized: "15 minutes", comment: "Batch size - 15min")
        case 6: return String(localized: "30 minutes", comment: "Batch size - 30min")
        case 12: return String(localized: "1 hour", comment: "Batch size - 1 hour")
        default: return ""
        }
    }
}
