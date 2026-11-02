import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @State private var showAdd = false
    @State private var filter = 0   // 0 all, 1 receivable, 2 payable

    private var active: [Entry] { entries.filter { !$0.isSettled } }
    private var toReceive: Double { active.filter { $0.isLent }.reduce(0) { $0 + $1.amount } }
    private var toGive: Double { active.filter { !$0.isLent }.reduce(0) { $0 + $1.amount } }

    private var shown: [Entry] {
        switch filter {
        case 1: return entries.filter { $0.isLent }
        case 2: return entries.filter { !$0.isLent }
        default: return entries
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        SummaryCard(title: "കിട്ടാനുള്ളത്", amount: toReceive,
                                    color: .green, icon: "arrow.down.left.circle.fill")
                        SummaryCard(title: "കൊടുക്കാനുള്ളത്", amount: toGive,
                                    color: .red, icon: "arrow.up.right.circle.fill")
                    }
                    Picker("", selection: $filter) {
                        Text("എല്ലാം").tag(0)
                        Text("കിട്ടാനുള്ളത്").tag(1)
                        Text("കൊടുക്കാനുള്ളത്").tag(2)
                    }.pickerStyle(.segmented)

                    LazyVStack(spacing: 10) {
                        ForEach(shown) { e in
                            NavigationLink { DetailView(entry: e) } label: { EntryRow(entry: e) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) { context.delete(e) } label: {
                                        Label("ഡിലീറ്റ്", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }.padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("കണക്കുപുസ്തകം")
            .toolbar {
                Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
            }
            .sheet(isPresented: $showAdd) { AddEntryView() }
        }
    }
}

struct SummaryCard: View {
    let title: String; let amount: Double; let color: Color; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).foregroundStyle(color).font(.title2)
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("₹\(amount, specifier: "%.0f")").font(.title2.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct EntryRow: View {
    let entry: Entry
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.isLent ? "arrow.down.left" : "arrow.up.right")
                .foregroundStyle(.white).frame(width: 40, height: 40)
                .background(entry.isLent ? Color.green : Color.red, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.person).font(.headline)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("₹\(entry.amount, specifier: "%.0f")").font(.headline)
                    .strikethrough(entry.isSettled)
                if entry.isSettled { Text("തീർന്നു").font(.caption2).foregroundStyle(.secondary) }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}
