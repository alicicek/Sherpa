import SwiftUI

struct StartupFailureView: View {
    let message: String
    let onRetry: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("We're having trouble loading your data")
                    .font(.title3)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                onRetry()
            }) {
                Text("Try Again")
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("startup-retry-button")
        }
        .padding()
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    StartupFailureView(message: "The data store could not be opened.") {}
}
