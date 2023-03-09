//
//  TestData.swift
//  TinyConverterTests
//
//  Created by Zildzic, Adnan on 09.03.23.
//  Copyright © 2023 Adnan Zildzic. All rights reserved.
//

@testable import TinyConverter
import Foundation

struct TestData {
    static let symbolsResponse = SymbolsResponse(success: true, error: nil, symbols: ["AED": "United Arab Emirates Dirham", "AFN": "Afghan Afghani", "ALL": "Albanian Lek", "AMD": "Armenian Dram", "ANG": "Netherlands Antillean Guilder", "AOA": "Angolan Kwanza", "ARS": "Argentine Peso", "AUD": "Australian Dollar", "AWG": "Aruban Florin", "EUR": "Euro", "USD": "United States Dollar"])

    static let exchangeRatesResponse = LatestRatesResponse(success: true,
                                                    error: nil,
                                                    timestamp: 1563038045,
                                                    base: "EUR",
                                                    date: "2019-07-13",
                                                    rates: ["AED": 4.14602, "AFN": 90.643209, "ALL": 122.248234, "AMD": 538.053473, "ANG": 2.009294, "AOA": 390.467138, "ARS":
                                                                46.877482, "AUD": 1.607685, "AWG": 2.031752, "EUR": 1, "USD": 1.128751])


    static let rates = [
        ExchangeRate(code: "AED", name: "United Arab Emirates Dirham", value: 4.14602),
        ExchangeRate(code: "AFN", name: "Afghan Afghani", value: 90.643209),
        ExchangeRate(code: "ALL", name: "Albanian Lek", value: 122.248234),
        ExchangeRate(code: "AMD", name: "Armenian Dram", value: 538.053473),
        ExchangeRate(code: "ANG", name: "Netherlands Antillean Guilder", value: 2.009294),
        ExchangeRate(code: "AOA", name: "Angolan Kwanza", value: 390.467138),
        ExchangeRate(code: "ARS", name: "Argentine Peso", value: 46.877482),
        ExchangeRate(code: "AUD", name: "Australian Dollar", value: 1.607685),
        ExchangeRate(code: "AWG", name: "Aruban Florin", value: 2.031752),
        ExchangeRate(code: "EUR", name: "Euro", value: 1),
        ExchangeRate(code: "USD", name: "United States Dollar", value: 1.128751)
    ]

    static let exchangeRates = ExchangeRates(baseCurrency: "EUR", date: Date().currentDate, rates: rates)

    static let exchangeRatesOld: ExchangeRates = ExchangeRates(baseCurrency: "EUR", date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, rates: rates)
}

extension String {
    static let successOnError = "Success returned on error."
    static let errorOnSuccess = "Error returned on success."
}
