//
//  DesignTokens.swift
//  Sherpa
//
//  Created by Codex on 15/10/2025.
//

import SwiftUI

/// Shared design system constants sourced from the Sherpa PRD.
enum DesignTokens {
    enum Colors {
        static let primary = Color(hex: "#58B62F")
        static let accentBlue = Color(hex: "#46A8E0")
        static let accentGold = Color(hex: "#F5C34D")
        static let accentPurple = Color(hex: "#7869FF")
        static let accentMint = Color(hex: "#7AE0B8")
        static let accentPink = Color(hex: "#FF90C2")
        static let accentOrange = Color(hex: "#FF9E5A")
        static let accentLavender = Color(hex: "#C6A6FF")
        static let success = Color(hex: "#2FAE60")
        static let warning = Color(hex: "#E85C4A")

        static let neutral: (g1: Color, g2: Color, g3: Color, g4: Color, g5: Color, g6: Color, g7: Color, g8: Color, g9: Color) = (
            g1: Color(hex: "#F6F7F8"),
            g2: Color(hex: "#EDEFF1"),
            g3: Color(hex: "#DFE3E6"),
            g4: Color(hex: "#CBD2D8"),
            g5: Color(hex: "#B1BAC2"),
            g6: Color(hex: "#939EA8"),
            g7: Color(hex: "#707C87"),
            g8: Color(hex: "#4F5963"),
            g9: Color(hex: "#2C343B")
        )
    }

    static let cardPalettes: [[Color]] = [
        [Colors.accentBlue, Colors.accentLavender],
        [Colors.accentGold, Colors.accentOrange],
        [Colors.accentPink, Colors.accentPurple],
        [Colors.accentMint, Colors.accentBlue],
        [Colors.accentPurple, Colors.accentGold]
    ]

    enum CornerRadius {
        static let large: CGFloat = 24
        static let medium: CGFloat = 20
        static let pill: CGFloat = 32
        static let small: CGFloat = 16
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 44
    }

    enum Gradients {
        static let sky = LinearGradient(
            colors: [
                Color(hex: "#F4FFE0"),
                Color(hex: "#DDF8FF"),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let playful = LinearGradient(
            colors: [
                Colors.primary.opacity(0.35),
                Colors.accentBlue.opacity(0.35),
                Colors.accentPink.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let night = LinearGradient(
            colors: [
                Color(hex: "#0D1126"),
                Color(hex: "#1A2552")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    enum Fonts {
        static func heroTitle() -> Font {
            .system(.title2, design: .rounded).weight(.bold)
        }

        static func sectionTitle() -> Font {
            .system(.headline, design: .rounded).weight(.semibold)
        }

        static func body() -> Font {
            .system(.body, design: .rounded)
        }

        static func captionUppercase() -> Font {
            .system(.caption, design: .rounded).weight(.semibold)
        }

        static func button() -> Font {
            .system(.subheadline, design: .rounded).weight(.semibold)
        }
    }
}

extension Color {
    /// Lightweight hex initialiser for design tokens.
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)
        let r, g, b: UInt64

        switch sanitized.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }

        self.init(
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0
        )
    }

    static let sherpaBackground = DesignTokens.Colors.neutral.g1
    static let sherpaPrimary = DesignTokens.Colors.primary
    static let sherpaTextPrimary = DesignTokens.Colors.neutral.g9
    static let sherpaTextSecondary = DesignTokens.Colors.neutral.g7
}

extension View {
    /// Applies a playful card styling used throughout the Sherpa UI.
    func sherpaCardStyle<S: ShapeStyle>(
        background: S = Color.white,
        padding: CGFloat = DesignTokens.Spacing.lg
    ) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.large, style: .continuous)
                    .fill(background)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 12, y: 8)
    }

    /// Applies a subtle raised capsule style used for pills and chips.
    func sherpaPillStyle<S: ShapeStyle>(
        background: S = Color.white,
        stroke: Color = Color.white.opacity(0.3)
    ) -> some View {
        self
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(background)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
    }
}
