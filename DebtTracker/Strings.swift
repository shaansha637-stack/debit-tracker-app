import Foundation

// English is the primary language. Malayalam is shown only when selected.
let mlStrings: [String: String] = [
    "Ledger": "കണക്കുപുസ്തകം",
    "Net balance": "ആകെ ബാലൻസ്",
    "To receive": "കിട്ടാനുള്ളത്",
    "To pay": "കൊടുക്കാനുള്ളത്",
    "All": "എല്ലാം",
    "Receivable": "കിട്ടാനുള്ളത്",
    "Payable": "കൊടുക്കാനുള്ളത്",
    "I gave": "ഞാൻ കൊടുത്തു",
    "I borrowed": "ഞാൻ വാങ്ങി",
    "You gave": "നിങ്ങൾ കൊടുത്തത്",
    "You borrowed": "നിങ്ങൾ വാങ്ങിയത്",
    "New entry": "പുതിയ എൻട്രി",
    "Name": "ആളുടെ പേര്",
    "Date & time": "തീയതി & സമയം",
    "Note (optional)": "കുറിപ്പ് (ഓപ്ഷണൽ)",
    "Payment screenshot / receipt": "പേയ്മെൻറ്റ് സ്ക്രീൻഷോട്ട് / റെസിപ്റ്റ്",
    "Choose photo": "ഫോട്ടോ തിരഞ്ഞെടുക്കുക",
    "Change photo": "ഫോട്ടോ മാറ്റുക",
    "Save entry": "സേവ് ചെയ്യുക",
    "Cancel": "റദ്ദാക്കുക",
    "Settled": "തീർന്നു",
    "Mark as settled": "തീർന്നതായി അടയാളപ്പെടുത്തുക",
    "Delete entry": "എൻട്രി ഡിലീറ്റ് ചെയ്യുക",
    "Delete": "ഡിലീറ്റ്",
    "No entries yet": "എൻട്രികൾ ഒന്നുമില്ല",
    "Tap + to add your first entry": "ആദ്യത്തെ എൻട്രി ചേർക്കാൻ + അമർത്തുക",
    "Language": "ഭാഷ",
    "Details": "വിവരങ്ങൾ",
    "Entries": "എൻട്രികൾ",
    "People": "ആളുകൾ",
    "Owes you": "നിങ്ങൾക്ക് തരാനുണ്ട്",
    "You owe": "നിങ്ങൾ കൊടുക്കാനുണ്ട്",
    "All settled": "എല്ലാം തീർന്നു",
    "entries": "എൻട്രികൾ",
    "Settle all": "എല്ലാം തീർക്കുക",
    "Settle all entries?": "എല്ലാ എൻട്രികളും തീർന്നതായി അടയാളപ്പെടുത്തണോ?",
    "History": "ചരിത്രം"
]

func tr(_ s: String) -> String {
    let lang = UserDefaults.standard.string(forKey: "lang") ?? "en"
    return lang == "ml" ? (mlStrings[s] ?? s) : s
}
