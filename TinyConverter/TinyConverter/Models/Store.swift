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
    private let apiKey = "b53418f0cda7fd7c937f4fd39851d5d1"
    private let serverHost = "http://data.fixer.io/api/"
    private let latestEndpoint = "latest"
    private let errorCodes = [NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed, NSURLErrorNetworkConnectionLost]

    private let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    private let storeLocation = "rates.json"

    static let shared = ConverterStore()

    func fetchData(_ completionHandler: @escaping (ExchangeRates?, Error?) -> Void) {
        let exchangeRates = getDataFromCache()

        if let exchangeRates = exchangeRates {
            let currentDate = Date().currentDate

            if exchangeRates.date == currentDate {
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
        guard let cachedData = try? Data(contentsOf: libraryDirectory.appendingPathComponent(storeLocation)) else {
            return nil
        }

        return try? JSONDecoder().decode(ExchangeRates.self, from: cachedData)
    }

    private func getDataFromServer(completionHandler: @escaping (ExchangeRates?, Error?) -> Void) {
        let url = getUrl(for: latestEndpoint)

        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let strongSelf = self else {
                completionHandler(nil, nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let jsonData = data else {
                if let error = error {
                    NSLog("Network data fetch done with error: \(error.localizedDescription).")

                    if strongSelf.errorCodes.contains(error._code) {
                        completionHandler(nil, .noConnection)
                    } else {
                        completionHandler(nil, .other)
                    }
                }

                return
            }

            guard let response = try? JSONDecoder().decode(LatestRatesResponse.self, from: jsonData) else {
                NSLog("Error while parsing json.")
                completionHandler(nil, .other)
                return
            }

            if let responseError = response.error {
                NSLog("Error returned from API: \(responseError.info).")
                completionHandler(nil, .apiError)
                return
            }

            let exchangeRates = strongSelf.parseRates(from: response)

            if let exchangeRatesJson = try? JSONEncoder().encode(exchangeRates) {
                strongSelf.cacheData(exchangeRatesJson)
            } else {
                NSLog("Error while parsing json. Data not saved to cache.")
            }

            NSLog("Network data fetch done with success.")
            completionHandler(exchangeRates, nil)
        }

        NSLog("Started data fetch from \(url).")
        task.resume()
    }

    private func getUrl(for endpoint: String) -> URL {
        let urlString = "\(serverHost)\(endpoint)?access_key=\(apiKey)"
        return URL(string: urlString)!
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
