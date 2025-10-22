import SwiftUI

/// Lightweight failure surface shown when the model container fails to start.
struct StartupFailureView: View {
    let message: String
    let onRetry: @MainActor () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Color.sherpaPrimary)
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(L10n.string("startup.title"))
                    .font(DesignTokens.Fonts.sectionTitle())
                    .foregroundStyle(Color.sherpaTextPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(DesignTokens.Fonts.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.sherpaTextSecondary)
                    .accessibilityIdentifier("startup-error-message")
            }

            Button(action: { onRetry() }) {
                Text(L10n.string("startup.retry"))
                    .font(DesignTokens.Fonts.button())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("startup-retry-button")
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.sherpaBackground.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("startup-failure-view")
    }
}

#Preview {
    StartupFailureView(message: "The data store could not be opened.") {}
}
