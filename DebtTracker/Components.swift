import SwiftUI
import UIKit

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

struct Currency: Identifiable, Hashable {
    let code: String
    let symbol: String
    let name: String
    var id: String { code }
}

let currencies: [Currency] = [
    Currency(code: "INR", symbol: "₹", name: "Indian Rupee"),
    Currency(code: "USD", symbol: "$", name: "US Dollar"),
    Currency(code: "EUR", symbol: "€", name: "Euro"),
    Currency(code: "GBP", symbol: "£", name: "British Pound"),
    Currency(code: "AED", symbol: "AED ", name: "UAE Dirham"),
    Currency(code: "SAR", symbol: "SAR ", name: "Saudi Riyal"),
    Currency(code: "QAR", symbol: "QAR ", name: "Qatari Riyal"),
    Currency(code: "KWD", symbol: "KWD ", name: "Kuwaiti Dinar"),
    Currency(code: "OMR", symbol: "OMR ", name: "Omani Rial"),
    Currency(code: "BHD", symbol: "BHD ", name: "Bahraini Dinar"),
    Currency(code: "SGD", symbol: "S$", name: "Singapore Dollar"),
    Currency(code: "MYR", symbol: "RM ", name: "Malaysian Ringgit"),
    Currency(code: "AUD", symbol: "A$", name: "Australian Dollar"),
    Currency(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
    Currency(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar"),
    Currency(code: "JPY", symbol: "¥", name: "Japanese Yen"),
    Currency(code: "CNY", symbol: "CN¥", name: "Chinese Yuan"),
    Currency(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar"),
    Currency(code: "CHF", symbol: "CHF ", name: "Swiss Franc"),
    Currency(code: "LKR", symbol: "Rs ", name: "Sri Lankan Rupee"),
    Currency(code: "BDT", symbol: "৳", name: "Bangladeshi Taka"),
    Currency(code: "THB", symbol: "฿", name: "Thai Baht"),
    Currency(code: "IDR", symbol: "Rp ", name: "Indonesian Rupiah"),
    Currency(code: "PHP", symbol: "₱", name: "Philippine Peso"),
    Currency(code: "KRW", symbol: "₩", name: "South Korean Won"),
    Currency(code: "ZAR", symbol: "R ", name: "South African Rand"),
    Currency(code: "TRY", symbol: "₺", name: "Turkish Lira"),
    Currency(code: "RUB", symbol: "₽", name: "Russian Ruble")
]

func symbol(for code: String) -> String {
    currencies.first { $0.code == code }?.symbol ?? (code + " ")
}

private let inFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 2
    f.locale = Locale(identifier: "en_IN")
    return f
}()

private let usFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 2
    f.locale = Locale(identifier: "en_US")
    return f
}()

func money(_ v: Double, _ code: String = "INR") -> String {
    let f = code == "INR" ? inFormatter : usFormatter
    let n = f.string(from: NSNumber(value: abs(v))) ?? "0"
    return (v < 0 ? "-" : "") + symbol(for: code) + n
}

struct CurrencyAmount: Identifiable {
    let code: String
    let amount: Double
    var id: String { code }
}

func amountsByCurrency(_ list: [Entry]) -> [CurrencyAmount] {
    Dictionary(grouping: list, by: { $0.currency })
        .map { CurrencyAmount(code: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
        .sorted { $0.code < $1.code }
}

func compressImage(_ ui: UIImage, maxDim: CGFloat = 1400) -> Data? {
    let scale = min(1, maxDim / max(ui.size.width, ui.size.height))
    let size = CGSize(width: ui.size.width * scale, height: ui.size.height * scale)
    let format = UIGraphicsImageRendererFormat.preferred()
    format.scale = 1
    let img = UIGraphicsImageRenderer(size: size, format: format).image { _ in
        ui.draw(in: CGRect(origin: .zero, size: size))
    }
    var q: CGFloat = 0.6
    var data = img.jpegData(compressionQuality: q)
    while let d = data, d.count > 700_000, q > 0.2 {
        q -= 0.1
        data = img.jpegData(compressionQuality: q)
    }
    return data
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
