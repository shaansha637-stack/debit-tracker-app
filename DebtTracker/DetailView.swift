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
                        .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                    Text(money(entry.amount, entry.currency))
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .strikethrough(entry.isSettled)
                    Text(entry.person).font(.title3.weight(.semibold)).foregroundStyle(.white)
                }
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity)
                .background((entry.isLent ? Color.green : Color.red).gradient,
                            in: RoundedRectangle(cornerRadius: 30, style: .continuous))

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(entry.date.formatted(date: .complete, time: .shortened), systemImage: "clock.fill")
                        if !entry.note.isEmpty {
                            Divider()
                            Label(entry.note, systemImage: "note.text")
                        }
                    }
                    .font(.subheadline)
                }

                Card {
                    Toggle(isOn: $entry.isSettled.animation(.spring())) {
                        Label(tr("Mark as settled"), systemImage: "checkmark.seal.fill")
                    }
                    .tint(.indigo)
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
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.12), in: Capsule())
                        .foregroundStyle(.red)
                }
                .buttonStyle(PressableStyle())
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
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
