import SwiftUI

struct AddHabitIconPickerView: View {
    @Binding var selectedIconId: String
    @Binding var selectedColor: HabitColorOption

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), count: 4)

    private var filteredGroups: [(HabitIconCategory, [HabitIconOption])] {
        HabitIconCategory.allCases.compactMap { category in
            let icons = HabitIconCatalog.icons(matching: searchText, category: category)
            return icons.isEmpty ? nil : (category, icons)
        }
    }

    private var currentIcon: HabitIconOption {
        HabitIconCatalog.icon(for: selectedIconId) ?? HabitIconCatalog.defaultIcon
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    previewSection
                    colorPaletteSection
                    iconGridSection
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .navigationTitle("Icon & Color")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: "Search icons")
        }
    }
}

private extension AddHabitIconPickerView {
    var previewSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(Color.sherpaTextPrimary)
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: currentIcon.systemName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(selectedColor.color)
                    .frame(width: 64, height: 64)
                    .background(selectedColor.color.opacity(0.15))
                    .clipShape(Circle())
                Text(currentIcon.label)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.sherpaTextPrimary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    var colorPaletteSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Accent color")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.sherpaTextSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(HabitColorPalette.options) { option in
                        Button {
                            selectedColor = option
                        } label: {
                            Circle()
                                .fill(option.color)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    if option.id == selectedColor.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(Color.white)
                                    }
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Select \(option.id) color")
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
            }
        }
    }

    var iconGridSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ForEach(filteredGroups, id: \.0.id) { category, icons in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(category.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.sherpaTextSecondary)
                    LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.sm) {
                        ForEach(icons) { icon in
                            Button {
                                selectedIconId = icon.id
                            } label: {
                                VStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: icon.systemName)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(icon.id == selectedIconId ? selectedColor.color : Color.sherpaTextSecondary)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(selectedColor.color.opacity(icon.id == selectedIconId ? 0.18 : 0.08))
                                        )
                                    Text(icon.label)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .foregroundStyle(Color.sherpaTextPrimary)
                                }
                                .padding(.vertical, DesignTokens.Spacing.xs)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(icon.accessibilityLabel)
                        }
                    }
                }
            }
        }
    }
}
