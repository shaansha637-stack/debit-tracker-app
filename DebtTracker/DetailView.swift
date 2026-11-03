import SwiftUI
import SwiftData

struct DetailView: View {
    @Bindable var entry: Entry
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lang") private var lang = "en"
    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(tr(entry.isLent ? "You gave" : "You borrowed"))
                        .font(.app(15)).foregroundStyle(.white.opacity(0.8))
                    Text(money(entry.amount, entry.currency))
                        .font(.app(50))
                        .foregroundStyle(.white)
                        .strikethrough(entry.isSettled)
                    Text(entry.person).font(.app(20)).foregroundStyle(.white)
                }
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .background((entry.isLent ? Theme.greenFill : Theme.redFill).gradient,
                            in: RoundedRectangle(cornerRadius: 30, style: .continuous))

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(entry.date.formatted(date: .complete, time: .shortened), systemImage: "clock.fill")
                        if !entry.note.isEmpty {
                            Divider()
                            Label(entry.note, systemImage: "note.text")
                        }
                    }
                    .font(.app(15))
                }

                Card {
                    Toggle(isOn: $entry.isSettled.animation(.spring())) {
                        Label(tr("Mark as settled"), systemImage: "checkmark.seal.fill")
                    }
                    .tint(Theme.accent)
                    .onChange(of: entry.isSettled) { _, _ in
                        haptic(.medium)
                        SyncService.push(entry)
                    }
                }

                if let d = entry.screenshot, let ui = UIImage(data: d) {
                    Card {
                        Image(uiImage: ui).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label(tr("Delete entry"), systemImage: "trash")
                        .font(.app(17))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.red.opacity(0.14), in: Capsule())
                        .foregroundStyle(Theme.red)
                }
                .buttonStyle(PressableStyle())
            }
            .padding()
        }
        .background(Theme.bg)
        .navigationTitle(tr("Details"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(tr("Delete entry"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(tr("Delete"), role: .destructive) {
                SyncService.remove(entry)
                context.delete(entry)
                dismiss()
            }
            Button(tr("Cancel"), role: .cancel) {}
        }
    }
}
