import LoopKitUI
import SwiftUI

struct EversenseOnboardingStart: View {
    @Environment(\.dismissAction) private var dismiss

    let nextAction: (Int) -> Void
    @State var value: Int?

    var body: some View {
        VStack(alignment: .leading) {
            List {
                Section {
                    CheckmarkListItem(
                        title: Text("Eversense E3", comment: "Eversense E3"),
                        description: Text(
                            "The eversense E3 is a 90 day or 180 day implant transmitter. The first Eversense implantable device build by Senseonics",
                            comment: "Eversense E3 description"
                        ),
                        isSelected: Binding(
                            get: { self.value == 0 },
                            set: { isSelected in
                                if isSelected {
                                    self.value = 0
                                }
                            }
                        )
                    )

                    CheckmarkListItem(
                        title: Text("Eversense 365", comment: "Eversense 365"),
                        description: Text(
                            "The eversense 365 is a full year implant transmitter, with improved algorithm compared to the Eversense E3",
                            comment: "Eversense 365 description"
                        ),
                        isSelected: Binding(
                            get: { self.value == 1 },
                            set: { isSelected in
                                if isSelected {
                                    self.value = 1
                                }
                            }
                        )
                    )
                } header: {
                    Text("Choose your Eversense transmitter", comment: "Onboarding subheader")
                }
                .buttonStyle(PlainButtonStyle()) // Disable row highlighting on selection
            }
            .insetGroupedListStyle()

            Spacer()

            Button(action: { if let value = value { nextAction(value) } }) {
                Text("Continue", comment: "Text for continue button")
            }
            .disabled(value == nil)
            .buttonStyle(ActionButtonStyle())
            .padding([.bottom, .horizontal])
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarHidden(false)
        .navigationTitle(String(localized: "Welcome!", comment: "Onboarding Header"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: dismiss) {
                    Text("Cancel", comment: "Cancel button title")
                }
            }
        }
    }
}
