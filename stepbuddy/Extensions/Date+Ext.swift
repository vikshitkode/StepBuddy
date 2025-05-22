//
//  Date+Ext.swift
//  stepbuddy
//
//  Created by Sai Vikshit Kode on 5/13/25.
//

import Foundation

extension Date {
    var weekdayInt: Int {
        Calendar.current.component(.weekday, from: self)
    }
}
