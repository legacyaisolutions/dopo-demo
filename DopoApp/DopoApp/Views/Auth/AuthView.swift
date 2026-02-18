import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            Color.dopoBg.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Logo
                VStack(spacing: 4) {
                    Text("dopo")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.dopoAccent, Color(red: 1.0, green: 0.6, blue: 0.42)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("YOUR BEST FINDS, ALL IN ONE PLACE")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.dopoTextDim)
                        .tracking(2)
                }

                Spacer().frame(height: 20)

                // Form
                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .textFieldStyle(DopoTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    SecureField("Password", text: $password)
                        .textFieldStyle(DopoTextFieldStyle())
                        .textContentType(isSignUp ? .newPassword : .password)

                    Button(action: submit) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.dopoAccent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting || email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.5 : 1)
                }

                // Error
                if let error = authManager.error {
                    Text(error)
                        .font(.dopoBody)
                        .foregroundColor(error.contains("created") ? .dopoSuccess : .dopoError)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Toggle
                Button(action: { isSignUp.toggle() }) {
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.dopoTextMuted)
                        Text(isSignUp ? "Sign in" : "Sign up")
                            .foregroundColor(.dopoAccent)
                    }
                    .font(.dopoBody)
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }

    private func submit() {
        isSubmitting = true
        Task {
            if isSignUp {
                await authManager.signUp(email: email, password: password)
            } else {
                await authManager.signIn(email: email, password: password)
            }
            isSubmitting = false
        }
    }
}

struct DopoTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.dopoSurface)
            .foregroundColor(.dopoText)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.dopoBorder, lineWidth: 1)
            )
            .font(.system(size: 15))
    }
}
