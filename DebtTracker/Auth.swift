import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

@MainActor
final class AuthManager: ObservableObject {
    @Published var user: User? = Auth.auth().currentUser
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }

    func signInWithGoogle() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "App", code: 1, userInfo: [NSLocalizedDescriptionKey:
                    "Google client ID missing. Enable Google sign-in in Firebase and re-download GoogleService-Info.plist."])
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else {
                throw NSError(domain: "App", code: 2, userInfo: [NSLocalizedDescriptionKey: "No window to present sign-in."])
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "App", code: 3, userInfo: [NSLocalizedDescriptionKey: "No ID token from Google."])
            }
            let cred = GoogleAuthProvider.credential(withIDToken: idToken,
                                                     accessToken: result.user.accessToken.tokenString)
            try await Auth.auth().signIn(with: cred)
        } catch {
            if (error as NSError).code == GIDSignInError.canceled.rawValue { return }
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
    }
}
