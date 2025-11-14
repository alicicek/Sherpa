import SwiftUI

struct HabitAreaPickerSheet: View {
    @Binding var selection: HabitAreaOption?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selection = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("No area")
                            Spacer()
                            if selection == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Section("Areas") {
                    ForEach(HabitAreaCatalog.options) { option in
                        Button {
                            selection = option
                            dismiss()
                        } label: {
                            HStack {
                                Label(option.name, systemImage: option.symbol)
                            Spacer()
                            if selection?.id == option.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.sherpaPrimary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            }
            .navigationTitle("Add to an area")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
