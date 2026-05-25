class DMSSettingsViewModel: ObservableObject {
    @Published var enabled: Bool = false {
        didSet { checkDirtyState() }
    }

    @Published var username: String = "" {
        didSet { checkDirtyState() }
    }

    @Published var password: String = "" {
        didSet { checkDirtyState() }
    }

    @Published var batchSize: Int = 1 {
        didSet { checkDirtyState() }
    }

    @Published var eversenseNowUsers: [NowFollowerUI] = []

    @Published var isDirty: Bool = false
    @Published var error: String = ""
    @Published var isLoading: Bool = false
    @Published var removeConfirmationSheet: Bool = false
    @Published var inviteNowSheet: Bool = false {
        didSet {
            guard let cgmManager else {
                return
            }
            updateFollowers(cgmManager)
        }
    }

    @Published var followerToBeRemoved: NowFollowerUI? = nil

    let batchSizeOptions: [Int] = [1, 3, 6, 12]

    let inviteNowViewModel: InviteNowViewModel
    private let cgmManager: EversenseCGMManager?
    init(cgmManager: EversenseCGMManager?, inviteNowViewModel: InviteNowViewModel) {
        self.cgmManager = cgmManager
        self.inviteNowViewModel = inviteNowViewModel

        guard let cgmManager else {
            return
        }

        stateDidUpdate(cgmManager.state)
        updateFollowers(cgmManager)
        cgmManager.addStateObserver(state: self, queue: DispatchQueue.main)
    }

    deinit {
        cgmManager?.removeStateObserver(state: self)
    }

    func updateFollowers(_ cgmManager: EversenseCGMManager) {
        guard let _ = cgmManager.state.username, let _ = cgmManager.state.password else {
            return
        }

        Task {
            let result = await DMSApi.updateFollowers(cgmManager: cgmManager)
            await MainActor.run {
                self.eversenseNowUsers = result
            }
        }
    }

    func confirmRemoveFollower(follower: NowFollowerUI) {
        followerToBeRemoved = follower
        removeConfirmationSheet = true
    }

    func removeFollower() {
        guard let cgmManager, let follower = followerToBeRemoved else {
            return
        }

        Task {
            await DMSApi.removeFollower(cgmManager: cgmManager, email: follower.FollowerEmail)
            let result = await DMSApi.updateFollowers(cgmManager: cgmManager)

            await MainActor.run {
                self.eversenseNowUsers = result
            }
        }
    }

    func save() {
        guard let cgmManager else {
            return
        }

        cgmManager.state.shouldUploadToEversenseDMS = enabled
        cgmManager.state.username = username
        cgmManager.state.password = password
        cgmManager.state.uploadBatchSize = batchSize
        cgmManager.notifyStateDidChange()
    }

    private func checkDirtyState() {
        guard let cgmManager else {
            return
        }

        DispatchQueue.main.async {
            self.isDirty = (
                cgmManager.state.shouldUploadToEversenseDMS != self.enabled ||
                    cgmManager.state.username != self.username ||
                    cgmManager.state.password != self.password ||
                    cgmManager.state.uploadBatchSize != self.batchSize
            )
        }
    }
}

extension DMSSettingsViewModel: StateObserver {
    func stateDidUpdate(_ state: EversenseCGMState) {
        DispatchQueue.main.async {
            self.enabled = state.shouldUploadToEversenseDMS
            self.username = state.username ?? ""
            self.password = state.password ?? ""
            self.batchSize = state.uploadBatchSize
            self.checkDirtyState()
        }
    }
}
