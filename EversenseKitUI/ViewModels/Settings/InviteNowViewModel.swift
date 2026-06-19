class InviteNowViewModel: ObservableObject {
    @Published var fullName: String = "" {
        didSet { checkValid() }
    }

    @Published var email: String = "" {
        didSet { checkValid() }
    }

    @Published var isLoading: Bool = false
    @Published var isValid: Bool = false

    var dismiss: (() -> Void)?

    private let cgmManager: EversenseCGMManager?
    init(cgmManager: EversenseCGMManager?) {
        self.cgmManager = cgmManager
    }

    func save() {
        guard let cgmManager else {
            return
        }

        isLoading = true

        Task {
            await DMSApi.inviteFollower(
                cgmManager: cgmManager,
                fullName: fullName,
                email: email
            )

            await MainActor.run {
                self.isLoading = false
                self.dismiss?()
            }
        }
    }

    func clear() {
        fullName = ""
        email = ""
        isValid = false
        isLoading = false
    }

    func checkValid() {
        let valid = fullName.count > 2 && email.isValidEmail
        DispatchQueue.main.async {
            self.isValid = valid
        }
    }
}

private extension String {
    var isValidEmail: Bool {
        let regex = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: regex, options: .regularExpression) != nil
    }
}
