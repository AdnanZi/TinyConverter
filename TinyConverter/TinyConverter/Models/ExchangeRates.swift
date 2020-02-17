//
//  ExchangeRates.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 07.09.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

struct ExchangeRates: Codable {
    let baseCurrency: String // TODO: Remove, not used
    let date: Date
    let rates: [ExchangeRate]
}

struct ExchangeRate: Codable {
    let code: String
    let name: String
    let value: Double
}
