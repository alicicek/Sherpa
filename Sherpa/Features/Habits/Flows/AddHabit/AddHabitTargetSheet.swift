import SwiftUI

struct AddHabitTargetSheet: View {
    @Binding var value: Double
    @Binding var unit: HabitTargetUnit

    @Environment(\.dismiss) private var dismiss
    @FocusState private var amountFieldFocused: Bool
    @State private var textValue: String = ""

    private let orderedUnits: [HabitTargetUnit] = [
        .calories, .count, .grams, .seconds, .minutes, .hours, .steps, .meters, .kilometers, .miles
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Live preview") {
                    Text("Daily target: \(HabitTargetUnitFormatter.display(for: value, unit: unit))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sherpaTextPrimary)
                }

                Section("Unit") {
                    ForEach(orderedUnits, id: \.self) { option in
                        Button {
                            unit = option
                            value = option.sanitizedValue(value)
                            updateTextField(with: value)
                        } label: {
                            HStack {
                                Text(option.displayName)
                                    .foregroundStyle(Color.sherpaTextPrimary)
                                Spacer()
                                if option == unit {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.sherpaPrimary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if unit.presetSuggestions.isEmpty == false {
                    Section("Common presets") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                ForEach(unit.presetSuggestions, id: \.self) { preset in
                                    Button {
                                        applyPreset(preset)
                                    } label: {
                                        Text(HabitTargetUnitFormatter.display(for: preset, unit: unit))
                                            .font(.footnote.weight(.medium))
                                            .padding(.horizontal, DesignTokens.Spacing.md)
                                            .padding(.vertical, DesignTokens.Spacing.xs)
                                            .background(
                                                Capsule()
                                                    .fill(Color.sherpaPrimary.opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, DesignTokens.Spacing.xs)
                        }
                    }
                }

                Section("Count") {
                    TextField("Enter amount", text: $textValue)
                        .keyboardType(unit.allowsDecimalInput ? .decimalPad : .numberPad)
                        .focused($amountFieldFocused)
                        .onChange(of: textValue) { _, newValue in
                            handleTextFieldChange(newValue)
                        }
                }
            }
            .navigationTitle("Daily target")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                updateTextField(with: value)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    amountFieldFocused = true
                }
            }
        }
    }
}

private extension AddHabitTargetSheet {
    func updateTextField(with newValue: Double) {
        if unit.allowsDecimalInput {
            textValue = String(format: "%g", newValue)
        } else {
            textValue = String(Int(newValue))
        }
    }

    func handleTextFieldChange(_ newValue: String) {
        let sanitized = sanitize(text: newValue)
        if sanitized != newValue {
            textValue = sanitized
        }
        let doubleValue = Double(sanitized) ?? 0
        let capped = min(doubleValue, 999_999_999)
        value = unit.sanitizedValue(capped)
    }

    func sanitize(text: String) -> String {
        var result = ""
        var digitCount = 0
        var hasDecimal = false

        for character in text {
            if character.isWholeNumber {
                guard digitCount < 9 else { continue }
                result.append(character)
                digitCount += 1
            } else if unit.allowsDecimalInput, character == ".", hasDecimal == false {
                hasDecimal = true
                result.append(character)
            }
        }

        return result
    }

    func applyPreset(_ preset: Double) {
        value = unit.sanitizedValue(preset)
        updateTextField(with: value)
    }
}
