import SwiftUI

struct DetailView: View {
    @Bindable var entry: Entry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.isLent ? "നിങ്ങൾ കൊടുത്തത്" : "നിങ്ങൾ വാങ്ങിയത്")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("₹\(entry.amount, specifier: "%.0f")").font(.system(size: 44, weight: .bold))
                Text(entry.person).font(.title3)
                Label(entry.date.formatted(date: .complete, time: .shortened), systemImage: "clock")
                if !entry.note.isEmpty { Label(entry.note, systemImage: "note.text") }

                Toggle("തീർന്നു (Settled)", isOn: $entry.isSettled)
                    .padding().background(.background, in: RoundedRectangle(cornerRadius: 14))

                if let d = entry.screenshot, let ui = UIImage(data: d) {
                    Image(uiImage: ui).resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }.padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}
