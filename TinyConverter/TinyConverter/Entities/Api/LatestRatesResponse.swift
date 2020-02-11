//
//  ExchangeRates.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 11.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

struct LatestRatesResponse: Codable, Response {
    let success: Bool
    let error: ErrorResponse?
    let timestamp: Int?
    let base: String?
    let date: String?
    let rates: [String: Double]?
}
