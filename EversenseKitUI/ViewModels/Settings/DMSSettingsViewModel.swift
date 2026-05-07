class DMSSettingsViewModel: ObservableObject {
    @Published var enabled: Bool = false
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var batchSize: Int = 1

    @Published var error: String = ""
    @Published var isLoading: Bool = false

    let batchSizeOptions: [Int] = [1, 3, 6, 12]

    private let cgmManager: EversenseCGMManager?
    init(cgmManager: EversenseCGMManager?) {
        self.cgmManager = cgmManager

        guard let cgmManager else {
            return
        }

        stateDidUpdate(cgmManager.state)
    }

    func stateDidUpdate(_ state: EversenseCGMState) {
        DispatchQueue.main.async {
            self.enabled = state.shouldUploadToEversenseDMS
            self.username = state.username ?? ""
            self.password = state.password ?? ""
            self.batchSize = state.uploadBatchSize

            Task {
                guard let cgmManager = self.cgmManager else {
                    return
                }
                let eversenseNowResult = await DMSApi.fetchEversenseNow(cgmManager: cgmManager)
            }
        }
    }

    func save() {}
}
