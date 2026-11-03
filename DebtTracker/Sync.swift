import Foundation
import SwiftData
import FirebaseAuth
import FirebaseFirestore

/// Keeps local SwiftData entries in sync with Firestore: users/{uid}/entries/{entry.uid}
final class SyncService: ObservableObject {
    private var listener: ListenerRegistration?

    static func collection() -> CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return Firestore.firestore().collection("users").document(uid).collection("entries")
    }

    static func push(_ e: Entry) {
        guard let col = collection() else { return }
        var data: [String: Any] = [
            "person": e.person,
            "amount": e.amount,
            "currency": e.currency,
            "isLent": e.isLent,
            "date": Timestamp(date: e.date),
            "note": e.note,
            "isSettled": e.isSettled
        ]
        if let s = e.screenshot { data["screenshot"] = s }
        col.document(e.uid).setData(data)
    }

    static func remove(_ e: Entry) {
        collection()?.document(e.uid).delete()
    }

    func start(context: ModelContext) {
        stop()
        guard let uid = Auth.auth().currentUser?.uid, let col = Self.collection() else { return }

        // One-time upload of entries that existed on this phone before cloud sync.
        let flag = "didInitialUpload_\(uid)"
        if !UserDefaults.standard.bool(forKey: flag) {
            if let local = try? context.fetch(FetchDescriptor<Entry>()) {
                local.forEach { Self.push($0) }
            }
            UserDefaults.standard.set(true, forKey: flag)
        }

        listener = col.addSnapshotListener { snap, _ in
            guard let snap else { return }
            for change in snap.documentChanges {
                if change.document.metadata.hasPendingWrites { continue }
                let id = change.document.documentID
                let existing = (try? context.fetch(
                    FetchDescriptor<Entry>(predicate: #Predicate { $0.uid == id })))?.first

                if change.type == .removed {
                    if let existing { context.delete(existing) }
                    continue
                }

                let d = change.document.data()
                let person = d["person"] as? String ?? ""
                let amount = d["amount"] as? Double ?? 0
                let currency = d["currency"] as? String ?? "INR"
                let isLent = d["isLent"] as? Bool ?? true
                let date = (d["date"] as? Timestamp)?.dateValue() ?? Date()
                let note = d["note"] as? String ?? ""
                let settled = d["isSettled"] as? Bool ?? false
                let shot = d["screenshot"] as? Data

                if let e = existing {
                    e.person = person; e.amount = amount; e.currency = currency; e.isLent = isLent
                    e.date = date; e.note = note; e.isSettled = settled; e.screenshot = shot
                } else {
                    let e = Entry(person: person, amount: amount, isLent: isLent,
                                  date: date, note: note, screenshot: shot, currency: currency, uid: id)
                    e.isSettled = settled
                    context.insert(e)
                }
            }
            try? context.save()
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }
}
