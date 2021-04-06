//
//  DateExtensions.swift
//  RescueLink
//
//  Created by Dario Talarico on 6/16/20.
//  Copyright © 2020 Security Union. All rights reserved.
//

import Foundation

extension Date {
    func addMonths(numberOfMonths: Int) -> Date {
        let endDate = Calendar.current.date(byAdding: .month, value: numberOfMonths, to: self)
        return endDate ?? Date()
    }

    func daysBefore(numberOfDays: Int) -> Date {
        let endDate = Calendar.current.date(byAdding: .day, value: (numberOfDays - (numberOfDays * 2)), to: self)
        return endDate ?? Date()
    }

    func toStringWithFormat() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DATE_FORMAT_WRITE
        return dateFormatter.string(from: self)
    }
    
    func toISO8601() -> String {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.string(from: self)
    }

    func toReadableDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: self)
    }
}
