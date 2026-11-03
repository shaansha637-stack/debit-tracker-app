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
    @State private var confirmSignOut = false
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var sync: SyncService
    @Namespace private var ns

    private var active: [Entry] { entries.filter { !$0.isSettled } }
    private func sums(lent: Bool) -> [CurrencyAmount] {
        amountsByCurrency(active.filter { $0.isLent == lent })
    }

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
        case .receivable: return all.filter { $0.nets.contains { $0.amount > 0 } }
        case .payable: return all.filter { $0.nets.contains { $0.amount < 0 } }
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
                                Text(tr("No entries yet")).font(.app(17))
                                Text(tr("Tap + to add your first entry"))
                                    .font(.app(15)).foregroundStyle(.secondary)
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
                                                withAnimation { SyncService.remove(e); context.delete(e) }
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
                        .font(.app(22))
                        .foregroundStyle(.white)
                        .frame(width: 62, height: 62)
                        .background(brandGradient, in: Circle())
                        .shadow(color: Theme.accent.opacity(0.45), radius: 14, y: 8)
                }
                .buttonStyle(PressableStyle())
                .padding(22)
            }
            .background(Theme.bg)
            .navigationTitle(tr("Ledger"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section(tr("Language")) {
                            Button("English") { lang = "en" }
                            Button("മലയാളം") { lang = "ml" }
                        }
                        Section(auth.user?.email ?? "") {
                            Button(role: .destructive) { confirmSignOut = true } label: {
                                Label(tr("Sign out"), systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    } label: {
                        Image(systemName: "person.crop.circle").font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddEntryView() }
            .confirmationDialog(tr("Sign out"), isPresented: $confirmSignOut, titleVisibility: .visible) {
                Button(tr("Sign out"), role: .destructive) {
                    sync.stop()
                    try? context.delete(model: Entry.self)
                    auth.signOut()
                }
                Button(tr("Cancel"), role: .cancel) {}
            } message: {
                Text(tr("Your data stays safe in the cloud"))
            }
        }
        .environment(\.locale, Locale(identifier: lang == "ml" ? "ml_IN" : "en_IN"))
    }

    private var headerCard: some View {
        HStack(alignment: .top, spacing: 16) {
            summaryColumn(icon: "arrow.down.left", title: tr("To receive"), items: sums(lent: true))
            summaryColumn(icon: "arrow.up.right", title: tr("To pay"), items: sums(lent: false))
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(brandGradient)
        .overlay(alignment: .topTrailing) {
            Circle().fill(.white.opacity(0.08)).frame(width: 170, height: 170).offset(x: 60, y: -70)
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Theme.accent.opacity(0.35), radius: 20, y: 10)
        .animation(.spring(), value: entries.count)
    }

    private func summaryColumn(icon: String, title: String, items: [CurrencyAmount]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.2), in: Circle())
                Text(title).font(.app(15)).foregroundStyle(.white.opacity(0.85))
            }
            if items.isEmpty {
                Text("—").font(.app(22)).foregroundStyle(.white.opacity(0.6))
            } else {
                ForEach(items) { it in
                    Text(money(it.amount, it.code))
                        .font(.app(26))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var modeBar: some View {
        HStack(spacing: 4) {
            modeButton(0, "Entries", "list.bullet")
            modeButton(1, "People", "person.2.fill")
        }
        .padding(4)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
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
            .font(.app(15))
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
                        .font(.app(13))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(filter == tab ? Theme.accent : Color.secondary)
                        .background {
                            if filter == tab {
                                Capsule().fill(Theme.accent.opacity(0.14))
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
                .font(.app(17))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background((entry.isLent ? Theme.greenFill : Theme.redFill).gradient, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.person).font(.app(17))
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.app(12)).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text((entry.isLent ? "+" : "-") + money(entry.amount, entry.currency))
                    .font(.app(17))
                    .foregroundStyle(entry.isLent ? Theme.green : Theme.red)
                    .strikethrough(entry.isSettled)
                if entry.isSettled {
                    Text(tr("Settled")).font(.app(11))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.gray.opacity(0.2), in: Capsule())
                }
            }
        }
        .padding(14)
        .cardSurface()
        .opacity(entry.isSettled ? 0.6 : 1)
    }
}
