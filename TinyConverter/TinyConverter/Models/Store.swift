//
//  Store.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 11.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

protocol Store {
    func fetchData(_ forceUpdate: Bool, _ completionHandler: @escaping (Result<ExchangeRates, Error>) -> Void)
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

    func fetchData(_ forceUpdate: Bool, _ completionHandler: @escaping (Result<ExchangeRates, Error>) -> Void) {
        NSLog("Fetching data...")

        let exchangeRates: ExchangeRates? = cacheService.getData(from: ratesFileName)

        if let exchangeRates {
            let currentDate = Date().currentDate

            if exchangeRates.date == currentDate && !forceUpdate {
                NSLog("Data retrieved from cache.")
                completionHandler(.success(exchangeRates))
                return
            }
        }

        getDataFromServer { result in
            switch result {
            case .success(let data):
                completionHandler(.success(data))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    func refreshData(_ completionHandler: @escaping (Bool) -> Void) {
        NSLog("Refreshing data...")

        if let exchangeRates: ExchangeRates = cacheService.getData(from: ratesFileName) {
            let currentDate = Date().currentDate

            if exchangeRates.date == currentDate {
                completionHandler(false)
            } else {
                getDataFromServer { result in
                    switch result {
                    case .success(_):
                        completionHandler(true)
                    case .failure(_):
                        completionHandler(false)
                    }
                }
            }
        }
    }

    private func getDataFromServer(_ completionHandler: @escaping (Result<ExchangeRates, Error>) -> Void) {
        apiService.getSymbols { [unowned self] result in
            switch result {
            case .failure(let error):
                completionHandler(.failure(error))
            case .success(let symbolsResponse):
                self.getExchangeRates(symbolsResponse, completionHandler: completionHandler)
            }
        }
    }

    private func getExchangeRates(_ symbolsResponse: SymbolsResponse, completionHandler: @escaping (Result<ExchangeRates, Error>) -> Void) {
        apiService.getLatestExchangeRates { [unowned self] result in
            switch result {
            case .failure(let error):
                completionHandler(.failure(error))
            case .success(let ratesResponse):
                if let responseError = ratesResponse.error {
                    NSLog("Error returned from API: \(responseError.info).")
                    completionHandler(.failure(.apiError))
                    return
                 }

                guard let exchangeRates = self.parseRates(ratesResponse: ratesResponse, symbolsResponse: symbolsResponse) else {
                    completionHandler(.failure(.other))
                    return
                }

                if let exchangeRatesJson = try? JSONEncoder().encode(exchangeRates) {
                    self.cacheService.cacheData(exchangeRatesJson, to: self.ratesFileName)
                } else {
                    NSLog("Error while deserializing json form ExchangeRates. Data not saved to cache.")
                }

                completionHandler(.success(exchangeRates))
            }
        }
    }

    private func parseRates(ratesResponse: LatestRatesResponse, symbolsResponse: SymbolsResponse) -> ExchangeRates? {
        guard let baseCurrency = ratesResponse.base, let dateString = ratesResponse.date, let rates = ratesResponse.rates, let symbols = symbolsResponse.symbols else {
            NSLog("Rates object missing required fields.")
            return nil
        }

        guard let date = Date.dateFromApiString(dateString) else {
            NSLog("Couldn't convert provided date: \(dateString)")
            return nil
        }

        let fullRates = rates.map { key, value in ExchangeRate(code: key, name: symbols[key]!, value: value) }

        return ExchangeRates(baseCurrency: baseCurrency, date: date, rates: fullRates)
    }
}
