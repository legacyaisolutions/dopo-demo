import SwiftUI

struct ErrorBanner: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Spacer()

            VStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 28))
                    .foregroundColor(.dopoError.opacity(0.7))

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.dopoTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button(action: retryAction) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                        Text("Try Again")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.dopoAccent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.dopoAccentGlow)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.dopoAccent.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            Spacer()
        }
    }
}

/// Inline toast-style error for non-blocking errors
struct InlineError: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.dopoError)
                .font(.system(size: 13))
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.dopoError)
            Spacer()
        }
        .padding(12)
        .background(Color.dopoError.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.dopoError.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}
