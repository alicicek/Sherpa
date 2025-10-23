//
//  L10n.swift
//  Sherpa
//
//  Central helper for localized strings across the app.
//

import Foundation

enum L10n {
    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        let value = NSLocalizedString(key, bundle: .main, comment: "")
        guard arguments.isEmpty == false else {
            return value
        }
        return String(format: value, locale: Locale.current, arguments: arguments)
    }

    static var addHabitsTitle: String {
        string("habits.addButton.title")
    }
}
