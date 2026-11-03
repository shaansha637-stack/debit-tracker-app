import SwiftUI
import SwiftData

@Model
final class Entry {
    var uid: String = UUID().uuidString   // id used for cloud sync
    var currency: String = "INR"
    var person: String
    var amount: Double
    var isLent: Bool          // true = I gave (receivable), false = I borrowed (payable)
    var date: Date
    var note: String
    var isSettled: Bool
    @Attribute(.externalStorage) var screenshot: Data?

    init(person: String, amount: Double, isLent: Bool, date: Date,
         note: String = "", screenshot: Data? = nil, currency: String = "INR",
         uid: String = UUID().uuidString) {
        self.uid = uid
        self.currency = currency
        self.person = person
        self.amount = amount
        self.isLent = isLent
        self.date = date
        self.note = note
        self.isSettled = false
        self.screenshot = screenshot
    }
}
