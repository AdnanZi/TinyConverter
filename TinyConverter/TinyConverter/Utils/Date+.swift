//
//  Date+.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 06.09.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

extension Date {
    var currentDate: Date {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let timeIntervalWithTimeZone = timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT())
        let timeInterval = floor(timeIntervalWithTimeZone / 86400) * 86400

        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }

    var dateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        return dateFormatter.string(from: self)
    }

    static func dateFromApiString(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        return dateFormatter.date(from: dateString)
    }
}
