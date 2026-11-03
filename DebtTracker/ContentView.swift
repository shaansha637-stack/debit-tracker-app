import SwiftUI
import SwiftData

enum FilterTab: String, CaseIterable, Identifiable {
    case all = "All", receivable = "Receivable", payable = "Payable"
    var id: String { rawValue }
}

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]
    @AppStorage("lang") private var lang = "en"
    @State private var showAdd = false
    @State private var filter: FilterTab = .all
    @State private var mode = 0   // 0 = Entries, 1 = People
    @Namespace private var ns

    private var active: [Entry] { entries.filter { !$0.isSettled } }
    private var toReceive: Double { active.filter { $0.isLent }.reduce(0) { $0 + $1.amount } }
    private var toGive: Double { active.filter { !$0.isLent }.reduce(0) { $0 + $1.amount } }

    private var shown: [Entry] {
        switch filter {
        case .receivable: return entries.filter { $0.isLent }
        case .payable: return entries.filter { !$0.isLent }
        case .all: return entries
        }
    }

    private var people: [PersonSummary] {
        let all = groupByPerson(entries)
        switch filter {
        case .receivable: return all.filter { $0.net > 0 }
        case .payable: return all.filter { $0.net < 0 }
        case .all: return all
        }
    }

    private func tabTitle(_ tab: FilterTab) -> String {
        if mode == 1 {
            switch tab {
            case .all: return tr("All")
            case .receivable: return tr("Owes you")
            case .payable: return tr("You owe")
            }
        }
        return tr(tab.rawValue)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        modeBar
                        filterBar

                        if (mode == 0 && shown.isEmpty) || (mode == 1 && people.isEmpty) {
                            VStack(spacing: 10) {
                                Image(systemName: "tray")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.secondary)
                                Text(tr("No entries yet")).font(.headline)
                                Text(tr("Tap + to add your first entry"))
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            .padding(.top, 50)
                        } else if mode == 0 {
                            LazyVStack(spacing: 12) {
                                ForEach(shown) { e in
                                    NavigationLink { DetailView(entry: e) } label: { EntryRow(entry: e) }
                                        .buttonStyle(PressableStyle())
                                        .transition(.scale.combined(with: .opacity))
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                withAnimation { context.delete(e) }
                                            } label: { Label(tr("Delete"), systemImage: "trash") }
                                        }
                                }
                            }
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(people) { p in
                                    NavigationLink { PersonDetailView(key: p.key) } label: { PersonRow(person: p) }
                                        .buttonStyle(PressableStyle())
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 110)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: filter)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: mode)
                }

                Button {
                    haptic(.medium)
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 62)
                        .background(brandGradient, in: Circle())
                        .shadow(color: .indigo.opacity(0.45), radius: 14, y: 8)
                }
                .buttonStyle(PressableStyle())
                .padding(22)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(tr("Ledger"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("English") { lang = "en" }
                        Button("മലയാളം") { lang = "ml" }
                    } label: {
                        Image(systemName: "globe").font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddEntryView() }
        }
        .environment(\.locale, Locale(identifier: lang == "ml" ? "ml_IN" : "en_IN"))
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(tr("Net balance"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(money(toReceive - toGive))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            HStack {
                stat(icon: "arrow.down.left", title: tr("To receive"), value: toReceive)
                Spacer()
                stat(icon: "arrow.up.right", title: tr("To pay"), value: toGive)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(brandGradient, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .indigo.opacity(0.35), radius: 20, y: 10)
        .animation(.spring(), value: toReceive - toGive)
    }

    private func stat(icon: String, title: String, value: Double) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.2), in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.caption).foregroundStyle(.white.opacity(0.75))
                Text(money(value)).font(.headline).foregroundStyle(.white)
            }
        }
    }

    private var modeBar: some View {
        HStack(spacing: 4) {
            modeButton(0, "Entries", "list.bullet")
            modeButton(1, "People", "person.2.fill")
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }

    private func modeButton(_ value: Int, _ title: String, _ icon: String) -> some View {
        Button {
            haptic()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { mode = value }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(tr(title))
            }
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .foregroundStyle(mode == value ? Color.white : Color.secondary)
            .background {
                if mode == value {
                    Capsule().fill(brandGradient)
                        .matchedGeometryEffect(id: "mode", in: ns)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var filterBar: some View {
        HStack(spacing: 4) {
            ForEach(FilterTab.allCases) { tab in
                Button {
                    haptic()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { filter = tab }
                } label: {
                    Text(tabTitle(tab))
                        .font(.footnote.weight(.semibold))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(filter == tab ? Color.indigo : Color.secondary)
                        .background {
                            if filter == tab {
                                Capsule().fill(Color.indigo.opacity(0.14))
                                    .matchedGeometryEffect(id: "pill", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct EntryRow: View {
    let entry: Entry
    var body: some View {
        HStack(spacing: 14) {
            Text(String(entry.person.prefix(1)).uppercased())
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background((entry.isLent ? Color.green : Color.red).gradient, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.person).font(.headline)
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text((entry.isLent ? "+" : "-") + money(entry.amount))
                    .font(.headline)
                    .foregroundStyle(entry.isLent ? Color.green : Color.red)
                    .strikethrough(entry.isSettled)
                if entry.isSettled {
                    Text(tr("Settled")).font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.gray.opacity(0.2), in: Capsule())
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .opacity(entry.isSettled ? 0.6 : 1)
    }
}
