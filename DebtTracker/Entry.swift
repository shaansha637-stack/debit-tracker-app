import SwiftUI
import SwiftData

@Model
final class Entry {
    var person: String
    var amount: Double
    var isLent: Bool          // true = ഞാൻ കൊടുത്തത് (കിട്ടാനുള്ളത്), false = എനിക്ക് കൊടുക്കാനുള്ളത്
    var date: Date
    var note: String
    var isSettled: Bool
    @Attribute(.externalStorage) var screenshot: Data?

    init(person: String, amount: Double, isLent: Bool, date: Date,
         note: String = "", screenshot: Data? = nil) {
        self.person = person
        self.amount = amount
        self.isLent = isLent
        self.date = date
        self.note = note
        self.isSettled = false
        self.screenshot = screenshot
    }
}
