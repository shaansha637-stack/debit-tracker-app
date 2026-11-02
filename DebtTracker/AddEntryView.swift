import SwiftUI
import SwiftData
import PhotosUI

struct AddEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var isLent = true
    @State private var person = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var imageData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Picker("തരം", selection: $isLent) {
                    Text("ഞാൻ കൊടുത്തു").tag(true)
                    Text("ഞാൻ വാങ്ങി").tag(false)
                }.pickerStyle(.segmented)

                Section("വിവരങ്ങൾ") {
                    TextField("ആളുടെ പേര്", text: $person)
                    TextField("തുക (₹)", text: $amountText).keyboardType(.decimalPad)
                    DatePicker("തീയതി & സമയം", selection: $date)
                    TextField("കുറിപ്പ്", text: $note)
                }

                Section("പേയ്മെൻറ്റ് സ്ക്രീൻഷോട്ട് / റെസിപ്റ്റ്") {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(imageData == nil ? "ഫോട്ടോ തിരഞ്ഞെടുക്കുക" : "മാറ്റുക",
                              systemImage: "photo.on.rectangle")
                    }
                    if let d = imageData, let ui = UIImage(data: d) {
                        Image(uiImage: ui).resizable().scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .navigationTitle("പുതിയ എൻട്രി")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("റദ്ദാക്കുക") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("സേവ്") { save() }
                        .disabled(person.isEmpty || Double(amountText) == nil)
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let ui = UIImage(data: data) {
                        imageData = ui.jpegData(compressionQuality: 0.7)
                    }
                }
            }
        }
    }

    private func save() {
        context.insert(Entry(person: person, amount: Double(amountText) ?? 0,
                             isLent: isLent, date: date, note: note, screenshot: imageData))
        dismiss()
    }
}
