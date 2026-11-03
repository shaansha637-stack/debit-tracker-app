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
    var gaveList: [CurrencyAmount] { amountsByCurrency(open.filter { $0.isLent }) }
    var borrowedList: [CurrencyAmount] { amountsByCurrency(open.filter { !$0.isLent }) }

    // per currency: positive = they owe me, negative = I owe them
    var nets: [CurrencyAmount] {
        let g = Dictionary(uniqueKeysWithValues: gaveList.map { ($0.code, $0.amount) })
        let b = Dictionary(uniqueKeysWithValues: borrowedList.map { ($0.code, $0.amount) })
        let codes = Set(g.keys).union(b.keys)
        return codes
            .map { CurrencyAmount(code: $0, amount: (g[$0] ?? 0) - (b[$0] ?? 0)) }
            .filter { abs($0.amount) > 0.0001 }
            .sorted { $0.code < $1.code }
    }

    var accent: Color {
        let pos = nets.contains { $0.amount > 0 }
        let neg = nets.contains { $0.amount < 0 }
        if pos && neg { return .orange }
        if pos { return .green }
        if neg { return .red }
        return .gray
    }
}

func groupByPerson(_ entries: [Entry]) -> [PersonSummary] {
    let groups = Dictionary(grouping: entries) { normalize($0.person) }
    return groups.map { key, list in
        PersonSummary(key: key, name: list[0].person, entries: list)
    }
    .sorted { a, b in
        (a.nets.isEmpty ? 1 : 0, a.name.lowercased()) < (b.nets.isEmpty ? 1 : 0, b.name.lowercased())
    }
}

func balanceInfo(_ net: Double) -> (String, Color) {
    if net > 0 { return (tr("Owes you"), .green) }
    if net < 0 { return (tr("You owe"), .red) }
    return (tr("All settled"), .gray)
}

struct PersonRow: View {
    let person: PersonSummary
    var body: some View {
        HStack(spacing: 14) {
            Text(String(person.name.prefix(1)).uppercased())
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(person.accent.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(person.name).font(.headline)
                Text("\(person.entries.count) \(tr("entries"))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                if person.nets.isEmpty {
                    Text(tr("All settled")).font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(person.nets) { n in
                        let info = balanceInfo(n.amount)
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(money(abs(n.amount), n.code))
                                .font(.headline)
                                .foregroundStyle(info.1)
                            Text(info.0).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
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

                    VStack(spacing: 14) {
                        Text(s.name).font(.title2.weight(.bold)).foregroundStyle(.white)
                        if s.nets.isEmpty {
                            Text(tr("All settled")).foregroundStyle(.white.opacity(0.85))
                        } else {
                            ForEach(s.nets) { n in
                                let info = balanceInfo(n.amount)
                                VStack(spacing: 2) {
                                    Text(info.0).font(.caption).foregroundStyle(.white.opacity(0.85))
                                    Text(money(abs(n.amount), n.code))
                                        .font(.system(size: 38, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .minimumScaleFactor(0.6)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 26)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .background(s.accent.gradient,
                                in: RoundedRectangle(cornerRadius: 30, style: .continuous))

                    HStack(alignment: .top, spacing: 12) {
                        Card {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tr("You gave")).font(.caption).foregroundStyle(.secondary)
                                if s.gaveList.isEmpty {
                                    Text("—").font(.title3.bold()).foregroundStyle(.secondary)
                                } else {
                                    ForEach(s.gaveList) { it in
                                        Text(money(it.amount, it.code)).font(.title3.bold()).foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                        Card {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tr("You borrowed")).font(.caption).foregroundStyle(.secondary)
                                if s.borrowedList.isEmpty {
                                    Text("—").font(.title3.bold()).foregroundStyle(.secondary)
                                } else {
                                    ForEach(s.borrowedList) { it in
                                        Text(money(it.amount, it.code)).font(.title3.bold()).foregroundStyle(.red)
                                    }
                                }
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
                withAnimation { for e in list { e.isSettled = true; SyncService.push(e) } }
            }
            Button(tr("Cancel"), role: .cancel) {}
        }
    }
}
