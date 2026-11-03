import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager
    @AppStorage("lang") private var lang = "en"

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            Circle().fill(Theme.accent.opacity(0.40)).frame(width: 320, height: 320)
                .blur(radius: 90).offset(x: -110, y: -250)
            Circle().fill(Color(hex: 0x22D3EE).opacity(0.20)).frame(width: 280, height: 280)
                .blur(radius: 90).offset(x: 130, y: 300)
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 88))
                    .foregroundStyle(.white)
                    .shadow(color: Theme.accent.opacity(0.7), radius: 24, y: 6)
                Text(tr("Ledger"))
                    .font(.app(36))
                    .foregroundStyle(.white)
                Text(tr("Sign in to back up and sync your data"))
                    .font(.app(15))
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
                        Text(tr("Continue with Google")).font(.app(17))
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
                        .font(.app(12))
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
                .font(.app(13))
                .foregroundStyle(.white)
                .padding(.bottom, 24)
            }
        }
    }
}
