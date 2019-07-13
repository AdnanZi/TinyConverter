//
//  Store.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 11.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import Foundation

class Store {
    private let apiKey = "b53418f0cda7fd7c937f4fd39851d5d1"
    private let serverHost = "http://data.fixer.io/api/"
    private let latestEndpoint = "latest"

    private let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    private let storeLocation = "rates.json"

    static let shared = Store()

    func fetchData(_ completionHandler: @escaping (ExchangeRates?) -> Void) {
        let exchangeRates = getDataFromCache()

        if let exchangeRates = exchangeRates {
            let currentDate = Date().currentDate

            if exchangeRates.date == currentDate {
                completionHandler(exchangeRates)
                return
            }
        }

        getDataFromServer { data in
            guard let data = data else {
                completionHandler(exchangeRates)
                return
            }

            completionHandler(data)
        }
    }

    func refreshData(_ completionHandler: @escaping (Bool) -> Void) {
        if let exchangeRates = getDataFromCache() {
            let currentDate = Date().currentDate

            if exchangeRates.date == currentDate {
                completionHandler(false)
            } else {
                getDataFromServer { data in
                    completionHandler(data != nil ? true : false)
                }
            }
        }
    }

    private func getDataFromCache() -> ExchangeRates? {
        guard let cachedData = try? Data(contentsOf: libraryDirectory.appendingPathComponent(storeLocation)) else {
            return nil
        }

        return try? JSONDecoder().decode(ExchangeRates.self, from: cachedData)
    }

    private func getDataFromServer(completionHandler: @escaping (ExchangeRates?) -> Void) {
        guard let url = getUrl(for: latestEndpoint) else {
            completionHandler(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let jsonData = data else {
                // TODO: Handle errors
                completionHandler(nil)
                return
            }

            guard let strongSelf = self else {
                completionHandler(nil)
                return
            }

            let response = try? JSONDecoder().decode(LatestRatesResponse.self, from: jsonData)

            if response == nil || response!.error != nil {
                // TODO: Handle errors
                completionHandler(nil)
                return
            }

            let exchangeRates = strongSelf.parseRates(from: response!)

            if let exchangeRatesJson = try? JSONEncoder().encode(exchangeRates) {
                strongSelf.cacheData(exchangeRatesJson)
            }

            completionHandler(exchangeRates)
        }

        task.resume()
    }

    private func getUrl(for endpoint: String) -> URL? {
        let urlString = "\(serverHost)\(endpoint)?access_key=\(apiKey)"
        return URL(string: urlString)
    }

    private func parseRates(from response: LatestRatesResponse) -> ExchangeRates? {
        guard let baseCurrency = response.base, let dateString = response.date, let rates = response.rates else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }

        return ExchangeRates(baseCurrency: baseCurrency, date: date, rates: rates)
    }

    private func cacheData(_ jsonData: Data) {
        let url = libraryDirectory.appendingPathComponent(storeLocation)

        try? jsonData.write(to: url)
    }
}

extension Date {
    var currentDate: Date {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let timeIntervalWithTimeZone = self.timeIntervalSinceReferenceDate + Double(timeZone.secondsFromGMT())
        let timeInterval = floor(timeIntervalWithTimeZone / 86400) * 86400

        return Date(timeIntervalSinceReferenceDate: timeInterval)
    }
}
