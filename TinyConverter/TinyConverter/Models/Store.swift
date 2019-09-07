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
    private let apiService: ApiService
    private let cacheService: CacheService
    private let cacheFileName = "rates"

    static let shared = ConverterStore()

    init(apiService: ApiService? = nil, cacheService: CacheService? = nil) {
        self.apiService = apiService ?? FixerApiService()
        self.cacheService = cacheService ?? CacheServiceImpl()
    }

    func fetchData(_ completionHandler: @escaping (ExchangeRates?, Error?) -> Void) {
        NSLog("Fetching data...")

        let exchangeRates: ExchangeRates? = cacheService.getData(from: cacheFileName)

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

        if let exchangeRates: ExchangeRates = cacheService.getData(from: cacheFileName) {
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
            cacheService.cacheData(exchangeRatesJson, to: cacheFileName)
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
}
