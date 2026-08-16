import LoopKitUI
import SwiftUI

struct EversenseAuth: View {
    @Environment(\.dismissAction) private var dismiss

    @ObservedObject var viewModel: Eversense365AuthViewModel

    var body: some View {
        VStack {
            List {
                Section {
                    TextField(String(localized: "Email Address", comment: "Label for email address"), text: $viewModel.username)
                        .textContentType(.emailAddress)
                    SecureField(String(localized: "Password", comment: "Label for password"), text: $viewModel.password)
                        .textContentType(.password)

                    Picker(selection: $viewModel.apiZone) {
                        ForEach(EversenseApiZone.all, id: \.self) { item in
                            Text(item == .US ? "US" : "Outside US")
                        }
                    } label: { Text("Where was your Eversense Tracker purchased?") }
                        .pickerStyle(.wheel)
                } footer: {
                    Text(
                        "If your Eversense 365 is already active, please make sure to use the same account",
                        comment: "login footer same account"
                    )
                }

                Section {
                    Button(action: viewModel.openRegistrationUrl) {
                        Text("Create Account", comment: "label to create account")
                    }
                    Button(action: viewModel.openForgotPasswordUrl) {
                        Text("Forgot Password", comment: "Label for forgot password")
                    }
                }
            }

            Spacer()

            if !viewModel.error.isEmpty {
                Text(viewModel.error)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 5) {
                if !viewModel.is365 {
                    Button(action: viewModel.nextStep) {
                        Text("Skip", comment: "label for Login")
                    }
                    .disabled(viewModel.username.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
                    .buttonStyle(ActionButtonStyle(.secondary))
                }

                Button(action: viewModel.login) {
                    Text("Login", comment: "label for Login")
                }
                .disabled(viewModel.username.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
                .buttonStyle(ActionButtonStyle())
            }
            .padding([.bottom, .horizontal])
        }
        .listStyle(InsetGroupedListStyle())
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: self.dismiss) {
                    Text("Cancel", comment: "Cancel button title")
                }
            }
        }
    }
}
