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
                    Text(LocalizedString("Choose your Eversense transmitter", comment: "Onboarding subheader"))
                }

                Section {
                    CheckmarkListItem(
                        title: Text(LocalizedString("Eversense E3", comment: "Eversense E3")),
                        description: Text(LocalizedString(
                            "The eversense E3 is a 90 day or 180 day implant transmitter. The first Eversense implantable device build by Senseonics",
                            comment: "Eversense E3 description"
                        )),
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
                        title: Text(LocalizedString("Eversense 365", comment: "Eversense 365")),
                        description: Text(LocalizedString(
                            "The eversense 365 is a full year implant transmitter, with improved algorithm compared to the Eversense E3",
                            comment: "Eversense 365 description"
                        )),
                        isSelected: Binding(
                            get: { self.value == 1 },
                            set: { isSelected in
                                if isSelected {
                                    self.value = 1
                                }
                            }
                        )
                    )
                }
                .buttonStyle(PlainButtonStyle()) // Disable row highlighting on selection
            }
            .insetGroupedListStyle()

            Spacer()

            Button(action: {
                if let value = value {
                    nextAction(value)
                }
            }) {
                Text(LocalizedString("Continue", comment: "Text for continue button"))
            }
            .disabled(value == nil)
            .buttonStyle(ActionButtonStyle())
            .padding([.bottom, .horizontal])
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarHidden(false)
        .navigationTitle(LocalizedString("Welcome!", comment: "Onboarding Header"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizedString("Cancel", comment: "Cancel button title"), action: {
                    self.dismiss()
                })
            }
        }
    }
}
