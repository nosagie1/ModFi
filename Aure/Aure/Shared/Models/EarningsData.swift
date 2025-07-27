//
//  EarningsData.swift
//  Aure
//
//  Created by Abdussalam Adesina on 7/10/25.
//

import Foundation

struct EarningsData: Identifiable {
    let id = UUID()
    let month: String
    let earnings: Double
}