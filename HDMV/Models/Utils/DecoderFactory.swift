//
//  DecoderFactory.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//


import Foundation

enum DecoderFactory {
    /// Returns a JSONDecoder configured to decode `yyyy-MM-dd` formatted dates.
    static func dateOnlyDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}
