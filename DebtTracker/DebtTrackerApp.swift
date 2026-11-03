import SwiftUI
import SwiftData
import FirebaseCore
import GoogleSignIn

@main
struct DebtTrackerApp: App {
    @StateObject private var auth: AuthManager
    @StateObject private var sync = SyncService()

    init() {
        FirebaseApp.configure()
        _auth = StateObject(wrappedValue: AuthManager())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(sync)
                .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
        }
        .modelContainer(for: Entry.self)
    }
}

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var sync: SyncService
    @Environment(\.modelContext) private var context

    var body: some View {
        Group {
            if auth.user != nil {
                ContentView().transition(.opacity)
            } else {
                LoginView().transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.user?.uid)
        .task(id: auth.user?.uid) {
            if auth.user != nil { sync.start(context: context) } else { sync.stop() }
        }
    }
}
