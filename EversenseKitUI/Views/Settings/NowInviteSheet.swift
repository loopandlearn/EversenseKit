import LoopKitUI
import SwiftUI

struct NowInviteSheet: View {
    @ObservedObject var viewModel: InviteNowViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        HStack {
                            Text("Full Name", comment: "invite form fullName")
                                .foregroundStyle(.primary)

                            TextField(String(""), text: $viewModel.fullName)
                                .textContentType(.name)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                        }

                        HStack {
                            Text("Email Address", comment: "invite form email")
                                .foregroundStyle(.primary)

                            TextField(String(""), text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                        }
                    }
                }

                Spacer()
                Button(action: viewModel.save) {
                    if viewModel.isLoading {
                        ActivityIndicator(isAnimating: .constant(true), style: .medium)
                    } else {
                        Text("Invite", comment: "label invite")
                    }
                }
                .buttonStyle(ActionButtonStyle())
                .padding([.bottom, .horizontal])
                .disabled(viewModel.isLoading || !viewModel.isValid)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.dismiss?() }) {
                        Text("Cancel", comment: "Cancel button title")
                    }
                }
            }
            .navigationTitle(String(localized: "Invite follower", comment: "invite now title"))
            .onAppear {
                viewModel.dismiss = { dismiss() }
            }
            .onDisappear {
                viewModel.clear()
            }
        }
    }
}
