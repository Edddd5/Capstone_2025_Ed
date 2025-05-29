//
//  ReviewDTO.swift
//  Market
//
//  Created by 장동혁 on 5/15/25.
//
import Foundation

struct ReviewRequestDTO: Codable {
    let rating: Int
    let comment: String
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
