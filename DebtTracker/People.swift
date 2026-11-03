import SwiftUI
import SwiftData

func normalize(_ s: String) -> String {
    s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

struct PersonSummary: Identifiable {
    let key: String
    let name: String
    let entries: [Entry]
    var id: String { key }

    private var open: [Entry] { entries.filter { !$0.isSettled } }
    var gave: Double { open.filter { $0.isLent }.reduce(0) { $0 + $1.amount } }
    var borrowed: Double { open.filter { !$0.isLent }.reduce(0) { $0 + $1.amount } }
    // positive = they owe me, negative = I owe them
    var net: Double { gave - borrowed }
}

func groupByPerson(_ entries: [Entry]) -> [PersonSummary] {
    let groups = Dictionary(grouping: entries) { normalize($0.person) }
    return groups.map { key, list in
        PersonSummary(key: key, name: list[0].person, entries: list)
    }
    .sorted { abs($0.net) > abs($1.net) }
}

func balanceInfo(_ net: Double) -> (String, Color) {
    if net > 0 { return (tr("Owes you"), .green) }
    if net < 0 { return (tr("You owe"), .red) }
    return (tr("All settled"), .gray)
}

struct PersonRow: View {
    let person: PersonSummary
    var body: some View {
        let info = balanceInfo(person.net)
        HStack(spacing: 14) {
            Text(String(person.name.prefix(1)).uppercased())
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(info.1.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name).font(.headline)
                Text("\(person.entries.count) \(tr("entries"))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(money(abs(person.net)))
                    .font(.headline)
                    .foregroundStyle(info.1)
                Text(info.0).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct PersonDetailView: View {
    let key: String
    @Query(sort: \Entry.date, order: .reverse) private var all: [Entry]
    @AppStorage("lang") private var lang = "en"
    @State private var confirmSettle = false

    private var list: [Entry] { all.filter { normalize($0.person) == key } }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !list.isEmpty {
                    let s = PersonSummary(key: key, name: list[0].person, entries: list)
                    let info = balanceInfo(s.net)

                    VStack(spacing: 8) {
                        Text(info.0).font(.subheadline).foregroundStyle(.white.opacity(0.85))
                        Text(money(abs(s.net)))
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(s.name).font(.title3.weight(.semibold)).foregroundStyle(.white)
                    }
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
                    .background(info.1.gradient,
                                in: RoundedRectangle(cornerRadius: 30, style: .continuous))

                    HStack(spacing: 12) {
                        Card {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tr("You gave")).font(.caption).foregroundStyle(.secondary)
                                Text(money(s.gave)).font(.title3.bold()).foregroundStyle(.green)
                            }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tr("You borrowed")).font(.caption).foregroundStyle(.secondary)
                                Text(money(s.borrowed)).font(.title3.bold()).foregroundStyle(.red)
                            }
                        }
                    }

                    Text(tr("History"))
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    LazyVStack(spacing: 12) {
                        ForEach(list) { e in
                            NavigationLink { DetailView(entry: e) } label: { EntryRow(entry: e) }
                                .buttonStyle(PressableStyle())
                        }
                    }

                    GradientButton(title: tr("Settle all"), icon: "checkmark.seal.fill",
                                   enabled: list.contains { !$0.isSettled }) {
                        confirmSettle = true
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(list.first?.person ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(tr("Settle all entries?"), isPresented: $confirmSettle,
                            titleVisibility: .visible) {
            Button(tr("Settle all")) {
                haptic(.medium)
                withAnimation { for e in list { e.isSettled = true } }
            }
            Button(tr("Cancel"), role: .cancel) {}
        }
    }
}
