import SwiftUI
import SwiftData
import PhotosUI

struct AddEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lang") private var lang = "en"
    @Namespace private var ns
    @Query(sort: \Entry.date, order: .reverse) private var existing: [Entry]

    @State private var isLent = true
    @AppStorage("lastCurrency") private var currency = "INR"
    @State private var person = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?

    private var suggestions: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for e in existing {
            if seen.insert(normalize(e.person)).inserted { out.append(e.person) }
        }
        let q = normalize(person)
        return out.filter { q.isEmpty || (normalize($0).contains(q) && normalize($0) != q) }
            .prefix(8).map { $0 }
    }

    private var valid: Bool { !person.trimmingCharacters(in: .whitespaces).isEmpty && Double(amountText) != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    typeSelector

                    Card {
                        HStack(spacing: 6) {
                            Spacer()
                            Menu {
                                Picker(tr("Currency"), selection: $currency) {
                                    ForEach(currencies) { c in
                                        Text("\(c.code) · \(c.name)").tag(c.code)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(symbol(for: currency).trimmingCharacters(in: .whitespaces))
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                    Image(systemName: "chevron.down").font(.caption.weight(.bold))
                                }
                                .foregroundStyle(.indigo)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.indigo.opacity(0.12), in: Capsule())
                            }
                            TextField("0", text: $amountText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .fixedSize()
                            Spacer()
                        }
                    }

                    Card {
                        VStack(spacing: 14) {
                            HStack {
                                Image(systemName: "person.fill").foregroundStyle(.indigo).frame(width: 24)
                                TextField(tr("Name"), text: $person)
                            }
                            if !suggestions.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(suggestions, id: \.self) { n in
                                            Button { person = n; haptic() } label: {
                                                Text(n).font(.caption.weight(.semibold))
                                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                                    .background(Color.indigo.opacity(0.12), in: Capsule())
                                                    .foregroundStyle(.indigo)
                                            }
                                            .buttonStyle(PressableStyle())
                                        }
                                    }
                                }
                            }
                            Divider()
                            HStack {
                                Image(systemName: "clock.fill").foregroundStyle(.indigo).frame(width: 24)
                                DatePicker(tr("Date & time"), selection: $date)
                            }
                            Divider()
                            HStack {
                                Image(systemName: "note.text").foregroundStyle(.indigo).frame(width: 24)
                                TextField(tr("Note (optional)"), text: $note)
                            }
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(tr("Payment screenshot / receipt"))
                                .font(.subheadline.weight(.semibold))
                            PhotosPicker(selection: $pickerItem, matching: .images) {
                                Label(imageData == nil ? tr("Choose photo") : tr("Change photo"),
                                      systemImage: "photo.on.rectangle.angled")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.indigo.opacity(0.12), in: Capsule())
                                    .foregroundStyle(.indigo)
                            }
                            .buttonStyle(PressableStyle())
                            if let d = imageData, let ui = UIImage(data: d) {
                                Image(uiImage: ui).resizable().scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }

                    GradientButton(title: tr("Save entry"), icon: "checkmark.circle.fill", enabled: valid) {
                        save()
                    }
                    .padding(.top, 4)
                }
                .padding()
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: imageData)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(tr("New entry"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(tr("Cancel")) { dismiss() } }
            }
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        imageData = compressImage(ui)
                    }
                }
            }
        }
    }

    private var typeSelector: some View {
        HStack(spacing: 4) {
            typeButton(lent: true, title: "I gave")
            typeButton(lent: false, title: "I borrowed")
        }
        .padding(4)
        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
    }

    private func typeButton(lent: Bool, title: String) -> some View {
        Button {
            haptic()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { isLent = lent }
        } label: {
            Text(tr(title))
                .font(.subheadline.weight(.semibold))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isLent == lent ? Color.white : Color.secondary)
                .background {
                    if isLent == lent {
                        Capsule().fill(lent ? Color.green : Color.red)
                            .matchedGeometryEffect(id: "type", in: ns)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func save() {
        let e = Entry(person: person.trimmingCharacters(in: .whitespaces),
                      amount: Double(amountText) ?? 0,
                      isLent: isLent, date: date, note: note, screenshot: imageData,
                      currency: currency)
        context.insert(e)
        SyncService.push(e)
        haptic(.medium)
        dismiss()
    }
}
