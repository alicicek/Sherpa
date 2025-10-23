//
//  Date+Helpers.swift
//  Sherpa
//
//  Created by Codex on 15/10/2025.
//

import Foundation

extension Date {
    /// Returns the start of the day using the current calendar.
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns the number of whole days between this date and another date.
    func days(since other: Date) -> Int {
        let calendar = Calendar.current
        let startA = calendar.startOfDay(for: self)
        let startB = calendar.startOfDay(for: other)
        let components = calendar.dateComponents([.day], from: startB, to: startA)
        return components.day ?? 0
    }

    /// Returns a new date by adding the supplied number of days.
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// Returns the week day index (1...7, Sunday = 1) for the date.
    var weekdayIndex: Int {
        Calendar.current.component(.weekday, from: self)
    }
}
