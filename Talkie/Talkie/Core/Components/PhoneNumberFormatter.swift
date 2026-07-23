//
//  PhoneNumberFormatter.swift
//  Talkie
//
//  Created by DS on 7/23/26.
//

import Foundation

enum PhoneNumberFormatter {
    static let requiredDigitCount = 11

    static func digits(from phoneNumber: String) -> String {
        String(phoneNumber.filter(\.isNumber).prefix(requiredDigitCount))
    }

    static func format(_ phoneNumber: String) -> String {
        let digits = digits(from: phoneNumber)

        guard digits.count > 3 else {
            return digits
        }

        let first = String(digits.prefix(3))
        let remainingAfterFirst = String(digits.dropFirst(3))

        guard remainingAfterFirst.count > 4 else {
            return "\(first)-\(remainingAfterFirst)"
        }

        let middle = String(remainingAfterFirst.prefix(4))
        let last = String(remainingAfterFirst.dropFirst(4))

        return "\(first)-\(middle)-\(last)"
    }

    static func isValid(_ phoneNumber: String) -> Bool {
        digits(from: phoneNumber).count == requiredDigitCount
    }
}
