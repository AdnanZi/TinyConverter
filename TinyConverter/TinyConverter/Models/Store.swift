//
//  Store.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 11.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import Foundation

protocol Store {
    func fetchData(_ completionHandler: @escaping (ExchangeRates?, Error?) -> Void)
}

class ConverterStore: Store {
    private let fileName: String
    private let apiService: ApiService

    static let shared = ConverterStore()

    private var storeLocation: URL {
        let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return libraryDirectory.appendingPathComponent("\(fileName).json")
    }

    init(apiService: ApiService? = nil, fileName: String? = nil) {
        self.apiService = apiService ?? FixerApiService()
        self.fileName = fileName ?? "rates"
    }

    func fetchData(_ completionHandler: @escaping (ExchangeRates?, Error?) -> Void) {
        NSLog("Fetching data...")

        let exchangeRates = getDataFromCache()

        if let exchangeRates = exchangeRates {
            let currentDate = Date().currentDate

            if exchangeRates.date == currentDate {
                NSLog("Data retrieved from cache.")
                completionHandler(exchangeRates, nil)
                return
            }
        }

        getDataFromServer { data, error in
            guard let data = data else {
                completionHandler(exchangeRates, error)
                return
            }

            completionHandler(data, nil)
        }
    }

    func refreshData(_ completionHandler: @escaping (Bool) -> Void) {
        NSLog("Refreshing data...")

        if let exchangeRates = getDataFromCache() {
            let currentDate = Date().currentDate

            if exchangeRates.date == currentDate {
                completionHandler(false)
            } else {
                getDataFromServer { data, _ in
                    completionHandler(data != nil ? true : false)
                }
            }
        }
    }

    private func getDataFromCache() -> ExchangeRates? {
        guard let cachedData = try? Data(contentsOf: storeLocation) else {
            return nil
        }

        return try? JSONDecoder().decode(ExchangeRates.self, from: cachedData)
    }

    private func getDataFromServer(_ completionHandler: @escaping (ExchangeRates?, Error?) -> Void) {
        apiService.getLatestExchangeRates { [weak self] apiResponse, error in
            self?.handleApiResponse(apiResponse, error, completionHandler)
        }
    }

    private func handleApiResponse(_ response: LatestRatesResponse?, _ error: Error?, _ completionHandler: @escaping (ExchangeRates?, Error?) -> Void) {
        if let error = error {
            completionHandler(nil, error)
            return
        }

        guard let response = response else {
            completionHandler(nil, .other)
            return
        }

        if let responseError = response.error {
            NSLog("Error returned from API: \(responseError.info).")
            completionHandler(nil, .apiError)
            return
        }

        let exchangeRates = parseRates(from: response)

        if let exchangeRatesJson = try? JSONEncoder().encode(exchangeRates) {
            cacheData(exchangeRatesJson)
        } else {
            NSLog("Error while deserializing json form ExchangeRates. Data not saved to cache.")
        }

        completionHandler(exchangeRates, nil)
    }

    private func parseRates(from response: LatestRatesResponse) -> ExchangeRates? {
        guard let baseCurrency = response.base, let dateString = response.date, let rates = response.rates else {
            return nil
        }

        guard let date = Date.dateFromApiString(dateString) else {
            return nil
        }

        return ExchangeRates(baseCurrency: baseCurrency, date: date, rates: rates)
    }

    private func cacheData(_ jsonData: Data) {
        try? jsonData.write(to: storeLocation)
    }
}

fileprivate extension Date {
    var currentDate: Date {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let timeIntervalWithTimeZone = timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT())
        let timeInterval = floor(timeIntervalWithTimeZone / 86400) * 86400

        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }

    static func dateFromApiString(_ dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        return dateFormatter.date(from: dateString)
    }
}
