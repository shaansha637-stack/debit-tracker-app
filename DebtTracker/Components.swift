import SwiftUI
import UIKit

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

func money(_ v: Double) -> String {
    let s = String(format: "₹%.0f", abs(v))
    return v < 0 ? "-" + s : s
}

let brandGradient = LinearGradient(colors: [.indigo, .purple],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct GradientButton: View {
    let title: String
    let icon: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(brandGradient, in: Capsule())
            .shadow(color: .indigo.opacity(enabled ? 0.35 : 0), radius: 12, y: 6)
            .opacity(enabled ? 1 : 0.4)
        }
        .buttonStyle(PressableStyle())
        .disabled(!enabled)
    }
}
