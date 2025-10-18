//
//  SherpaUIComponents.swift
//  Sherpa
//
//  Created by Codex on 17/10/2025.
//

import SwiftUI

/// Shared reusable containers that capture the Playful Sherpa visual language.
struct SherpaCard<Content: View>: View {
    enum BackgroundStyle {
        case solid(Color)
        case gradient(LinearGradient)
        case palette([Color])
    }

    private let backgroundStyle: BackgroundStyle
    private let strokeColor: Color?
    private let strokeOpacity: Double
    private let padding: CGFloat
    private let shadowColor: Color
    private let content: Content

    init(
        backgroundStyle: BackgroundStyle = .solid(Color.white),
        strokeColor: Color? = nil,
        strokeOpacity: Double = 0.25,
        padding: CGFloat = DesignTokens.Spacing.lg,
        shadowColor: Color = Color.black.opacity(0.08),
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundStyle = backgroundStyle
        self.strokeColor = strokeColor
        self.strokeOpacity = strokeOpacity
        self.padding = padding
        self.shadowColor = shadowColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous)
                    .fill(fillStyle)
            )
            .overlay {
                if let strokeColor = strokeColor {
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous)
                        .stroke(strokeColor.opacity(strokeOpacity), lineWidth: 1)
                }
            }
            .shadow(color: shadowColor, radius: 16, y: 10)
    }

    private var fillStyle: AnyShapeStyle {
        switch backgroundStyle {
        case let .solid(color):
            return AnyShapeStyle(color)
        case let .gradient(gradient):
            return AnyShapeStyle(gradient)
        case let .palette(colors):
            let resolved = LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            return AnyShapeStyle(resolved)
        }
    }
}

enum SherpaChipStyle {
    case neutral
    case accent(Color)
    case gradient([Color])
}

struct SherpaChip<Content: View>: View {
    private let style: SherpaChipStyle
    private let isSelected: Bool
    private let content: Content
    private let cornerRadius: CGFloat
    private let horizontalPadding: CGFloat
    private let verticalPadding: CGFloat
    private let font: Font?

    init(
        style: SherpaChipStyle = .neutral,
        isSelected: Bool = false,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.pill,
        horizontalPadding: CGFloat = DesignTokens.Spacing.lg,
        verticalPadding: CGFloat = DesignTokens.Spacing.sm,
        font: Font? = DesignTokens.Fonts.button(),
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.isSelected = isSelected
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.font = font
        self.content = content()
    }

    var body: some View {
        chipLabel
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: 8, y: 4)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    @ViewBuilder
    private var chipLabel: some View {
        if let font = font {
            content.font(font)
        } else {
            content
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .neutral:
            return isSelected ? Color.white : Color.sherpaTextPrimary
        case let .accent(color):
            return isSelected ? Color.white : color
        case .gradient:
            return Color.white
        }
    }

    private var backgroundFill: AnyShapeStyle {
        switch style {
        case .neutral:
            if isSelected {
                return AnyShapeStyle(LinearGradient(colors: [DesignTokens.Colors.primary, DesignTokens.Colors.accentBlue], startPoint: .topLeading, endPoint: .bottomTrailing))
            } else {
                return AnyShapeStyle(Color.white.opacity(0.9))
            }
        case let .accent(color):
            if isSelected {
                return AnyShapeStyle(color)
            } else {
                return AnyShapeStyle(color.opacity(0.22))
            }
        case let .gradient(colors):
            return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private var borderColor: Color {
        switch style {
        case .neutral:
            return isSelected ? Color.white.opacity(0.8) : Color.white.opacity(0.3)
        case let .accent(color):
            return color.opacity(isSelected ? 0.6 : 0.35)
        case .gradient:
            return Color.white.opacity(isSelected ? 0.8 : 0.4)
        }
    }

    private var shadowColor: Color {
        switch style {
        case .neutral:
            return isSelected ? DesignTokens.Colors.primary.opacity(0.28) : Color.black.opacity(0.08)
        case let .accent(color):
            return color.opacity(isSelected ? 0.4 : 0.12)
        case let .gradient(colors):
            return colors.last?.opacity(0.32) ?? Color.black.opacity(0.12)
        }
    }
}

struct SherpaBadge: View {
    enum Kind {
        case xp
        case streak
        case neutral
    }

    let text: String
    var kind: Kind = .neutral
    var icon: String?

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if let icon = icon {
                Text(icon)
            }
            Text(text.uppercased())
                .font(.caption2.weight(.heavy))
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .foregroundStyle(Color.white)
        .background(
            Capsule(style: .continuous)
                .fill(backgroundColor)
        )
        .shadow(color: backgroundColor.opacity(0.35), radius: 6, y: 3)
    }

    private var backgroundColor: Color {
        switch kind {
        case .xp: return DesignTokens.Colors.accentGold
        case .streak: return DesignTokens.Colors.primary
        case .neutral: return DesignTokens.Colors.accentPurple
        }
    }
}
