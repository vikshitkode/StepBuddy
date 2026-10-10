//
//  TestDates.swift
//  stepbuddyTests
//
//  Created by Sai Vikshit Kode on 10/10/26.
//

import Foundation

enum TestDates {
    /// Monday, Sep 7 2026 at midnight, in the current calendar and time zone like the app's own dates
    static let monday: Date = {
        guard let date = Calendar.current.date(from: DateComponents(year: 2026, month: 9, day: 7)) else {
            fatalError("Invalid test date")
        }
        return date
    }()

    /// The day `offset` days after `monday` (0 = Monday, 1 = Tuesday, 6 = Sunday, 7 = next Monday)
    static func day(_ offset: Int) -> Date {
        guard let date = Calendar.current.date(byAdding: .day, value: offset, to: monday) else {
            fatalError("Invalid test date offset \(offset)")
        }
        return date
    }
}
