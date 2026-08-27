//
//  Date+Extensions.swift
//  FreeAudiobooks
//
//  Created by Ed Beecroft on 24/06/2019.
//  Copyright © 2020 Radically Better Ltd. All rights reserved.
//

import Foundation

extension Date {
	func toString(dateFormat format: String) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = format
		return dateFormatter.string(from: self)
	}
}

class DateFormatters {
    static var shortDateFormatterWithYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")!
        formatter.locale = Locale.current
        formatter.calendar = Calendar.utc
        formatter.setLocalizedDateFormatFromTemplate("MM/dd/yy")
        return formatter
    }
    static var midDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")!
        formatter.locale = Locale.current
        formatter.calendar = Calendar.utc
        formatter.setLocalizedDateFormatFromTemplate("MMM d, yyyy")
        return formatter
    }
    static var longDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.locale = Locale.current
        formatter.calendar = Calendar.current
        formatter.setLocalizedDateFormatFromTemplate("h:mm a, MMM d yyyy")
        return formatter
    }
	static var timeFormatter: DateFormatter {
		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm"
		return formatter
	}
    static var utcFormatterWithoutYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")!
        formatter.locale = Locale.current
        formatter.calendar = Calendar.utc
        formatter.dateFormat = "d MMMM"
        return formatter
    }
	static var localFormatterWithoutYear: DateFormatter {
		let formatter = DateFormatter()
		formatter.timeZone = TimeZone.current
		formatter.locale = Locale.current
		formatter.calendar = Calendar.current
		formatter.dateFormat = "d MMMM"
		return formatter
	}
	static var localFormatterWithYear: DateFormatter {
		let formatter = DateFormatter()
		formatter.timeZone = TimeZone.current
		formatter.locale = Locale.current
		formatter.calendar = Calendar.current
		formatter.dateFormat = "d MMMM YYYY"
		return formatter
	}
}

extension DateFormatters {
    static let dayOrDateSentFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")!
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        return formatter
    }()
    static let messagesDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")!
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        return formatter
    }()

    /// Formatter for early access dates in YYYY-MM-DD format
    /// Used for storing and parsing availableForAllDateString
    static let earlyAccessDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension Calendar {
	static let utc: Calendar  = {
		var calendar = Calendar.current
		calendar.timeZone = TimeZone(identifier: "UTC")!
		return calendar
	}()
	static let localTime: Calendar  = {
		var calendar = Calendar.current
		calendar.timeZone = .current
		return calendar
	}()
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let fromDate = startOfDay(for: from)
        let toDate = startOfDay(for: to)
        let numberOfDays = dateComponents([.day], from: fromDate, to: toDate)
        
        return numberOfDays.day ?? 0 + 1
    }
}

extension Date {
	static func dateFromCustomString(customString: String) -> Date {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MM/dd/yyyy"
		return dateFormatter.date(from: customString) ?? Date()
	}
}

extension Date {
    
    var dayOrDateSentString: String {
        
        let minute:TimeInterval = 60.0
        let hour:TimeInterval = 60.0 * minute
        let day:TimeInterval = 24 * hour
        let week:TimeInterval = 7 * day
        //let month:TimeInterval = 31 * day
        let year: TimeInterval = 365 * day
        
        let today = Date()
        
        let startOfToday = Calendar.utc.startOfDay(for: today)
        guard let startOfYesterday = Calendar.utc.date(byAdding: .day, value: -1, to: startOfToday) else {return ""}
        
        let dateFormatter = DateFormatters.dayOrDateSentFormatter
        
        if self > startOfToday {
            return localizedStringTime
        } else if self < today - year {
            dateFormatter.dateFormat = "yyyy"
        } else if self < today - week {
            //dateFormatter.dateFormat = "dd/MM/yyyy"
        }  else if self < startOfYesterday {
            dateFormatter.dateFormat = "EEEE"
        } else if self < startOfToday {
            return "Yesterday"
        }
        return dateFormatter.string(from: self)
    }
    
    func reduceToMonthDayYear() -> Date {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)
        let year = calendar.component(.year, from: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: "\(month)/\(day)/\(year)") ?? Date()
    }
}

extension Date {
    
    static func randomBetween(start: String, end: String, format: String = "yyyy-MM-dd") -> String {
        let date1 = Date.parse(start, format: format)
        let date2 = Date.parse(end, format: format)
        return Date.randomBetween(start: date1, end: date2).dateString(format)
    }

    static func randomBetween(start: Date, end: Date) -> Date {
        let date1 = min(start, end)
        var date2 = max(start, end)
        
        if date1 == date2 {
            date2 = date1.addingTimeInterval(120)
        }
        let span = TimeInterval.random(in: date1.timeIntervalSinceNow...date2.timeIntervalSinceNow)
        return Date(timeIntervalSinceNow: span)
    }

    func dateString(_ format: String = "yyyy-MM-dd") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }

    static func parse(_ string: String, format: String = "yyyy-MM-dd") -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone.default
        dateFormatter.dateFormat = format

        let date = dateFormatter.date(from: string)!
        return date
    }
}

extension Date {
    var localizedStringTime: String {
        return DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: .short)
    }
}

extension Date {
    var localizedDateString: String {
        return DateFormatter.localizedString(from: self, dateStyle: .short, timeStyle: .none)
    }
    var localizedMediumDateString: String {
        return DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .none)
    }
    var localizedFullDateString: String {
        return DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .medium)
    }
    var localizedDateTimeString: String {
        return DateFormatter.localizedString(from: self, dateStyle: .short, timeStyle: .short)
    }
}
