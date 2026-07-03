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

            Button(action: viewModel.login) {
                Text("Login", comment: "label for Login")
            }
            .disabled(viewModel.username.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
            .buttonStyle(ActionButtonStyle())
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
