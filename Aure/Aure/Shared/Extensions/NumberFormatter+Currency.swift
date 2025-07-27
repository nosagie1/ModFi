//
//  NumberFormatter+Currency.swift
//  Aure
//
//  Currency and number formatting extensions
//

import Foundation

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0 // No cents for most amounts
        return formatter
    }()
    
    static let currencyWithCents: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2 // With cents
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

extension Double {
    var formatAsCurrency: String {
        NumberFormatter.currency.string(from: NSNumber(value: self)) ?? "$0"
    }
    
    var formatAsCurrencyWithCents: String {
        NumberFormatter.currencyWithCents.string(from: NSNumber(value: self)) ?? "$0.00"
    }
    
    var formatWithCommas: String {
        NumberFormatter.decimal.string(from: NSNumber(value: self)) ?? "0"
    }
}

extension Int {
    var formatWithCommas: String {
        NumberFormatter.decimal.string(from: NSNumber(value: self)) ?? "0"
    }
}