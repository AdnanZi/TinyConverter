//
//  Store.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 11.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

protocol Store {
    func fetchData(_ forceUpdate: Bool, _ completionHandler: @escaping (ExchangeRates?, ApiError?) -> Void)
    func refreshData(_ completionHandler: @escaping (Bool) -> Void)
}

class ConverterStore: Store {
    private let apiService: ApiService
    private let cacheService: CacheService
    private let ratesFileName = "rates"

    init(apiService: ApiService, cacheService: CacheService) {
        self.apiService = apiService
        self.cacheService = cacheService
    }

    func fetchData(_ forceUpdate: Bool, _ completionHandler: @escaping (ExchangeRates?, ApiError?) -> Void) {
        NSLog("Fetching data...")

        let exchangeRates: ExchangeRates? = cacheService.getData(from: ratesFileName)

        if let exchangeRates = exchangeRates {
            let currentDate = Date().currentDate

            if exchangeRates.date == currentDate && !forceUpdate {
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

        if let exchangeRates: ExchangeRates = cacheService.getData(from: ratesFileName) {
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

    private func getDataFromServer(_ completionHandler: @escaping (ExchangeRates?, ApiError?) -> Void) {
        getSymbolsFromServer { [weak self] symbolsResponse, error in
            guard let strongSelf = self else {
                completionHandler(nil, nil)
                return
            }

            if let error = error {
                completionHandler(nil, error)
                return
            }

            strongSelf.getExchangeRatesFromServer { ratesResponse, error in
                if let error = error {
                    completionHandler(nil, error)
                    return
                }

                let exchangeRates = strongSelf.parseRates(ratesResponse: ratesResponse!, symbolsResponse: symbolsResponse!)

                if let exchangeRatesJson = try? JSONEncoder().encode(exchangeRates) {
                    let _: () = strongSelf.cacheService.cacheData(exchangeRatesJson, to: strongSelf.ratesFileName)
                } else {
                    NSLog("Error while deserializing json form ExchangeRates. Data not saved to cache.")
                }

                completionHandler(exchangeRates, nil)
            }
        }
    }

    private func getSymbolsFromServer(_ completionHandler: @escaping (SymbolsResponse?, ApiError?) -> Void) {
        apiService.getSymbols { [weak self] apiResponse, error in
            guard let strongSelf = self else { return }

            if let error = strongSelf.validateResponse(apiResponse, error) {
                completionHandler(nil, error)
                return
            }

            completionHandler(apiResponse!, nil)
        }
    }

    private func getExchangeRatesFromServer(_ completionHandler: @escaping (LatestRatesResponse?, ApiError?) -> Void) {
        apiService.getLatestExchangeRates { [weak self] apiResponse, error in
            guard let strongSelf = self else { return }

            if let error = strongSelf.validateResponse(apiResponse, error) {
                completionHandler(nil, error)
                return
            }

            completionHandler(apiResponse!, nil)
        }
    }

    private func validateResponse(_ response: Response?, _ error: ApiError?) -> ApiError? {
        if let error = error {
            return error
        }

        guard let response = response else {
            return .other
        }

        if let responseError = response.error {
            NSLog("Error returned from API: \(responseError.info).")
            return .apiError
        }

        return nil
    }

    private func parseRates(ratesResponse: LatestRatesResponse, symbolsResponse: SymbolsResponse) -> ExchangeRates? {
        guard let baseCurrency = ratesResponse.base, let dateString = ratesResponse.date, let rates = ratesResponse.rates, let symbols = symbolsResponse.symbols else {
            return nil
        }

        guard let date = Date.dateFromApiString(dateString) else {
            return nil
        }

        let fullRates = rates.map { key, value in ExchangeRate(code: key, name: symbols[key]!, value: value) }

        return ExchangeRates(baseCurrency: baseCurrency, date: date, rates: fullRates)
    }
}
