import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @AppStorage("lang") private var lang = "en"

    var body: some View {
        ZStack {
            brandGradient.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                Text(tr("Ledger"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(tr("Sign in to back up and sync your data"))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 40)
                Spacer()

                Button {
                    haptic(.medium)
                    Task { await auth.signInWithGoogle() }
                } label: {
                    HStack(spacing: 10) {
                        if auth.isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "g.circle.fill").font(.title2).foregroundStyle(.red)
                        }
                        Text(tr("Continue with Google")).font(.headline)
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white, in: Capsule())
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                }
                .buttonStyle(PressableStyle())
                .disabled(auth.isLoading)
                .padding(.horizontal, 32)

                if let msg = auth.errorMessage {
                    Text(msg)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                }

                HStack(spacing: 18) {
                    Button("English") { lang = "en" }
                        .fontWeight(lang == "en" ? .bold : .regular)
                    Button("മലയാളം") { lang = "ml" }
                        .fontWeight(lang == "ml" ? .bold : .regular)
                }
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(.bottom, 24)
            }
        }
    }
}
