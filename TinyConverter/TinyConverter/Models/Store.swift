//
//  Store.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 11.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation
import Combine

protocol Store {
    func fetchData(_ forceUpdate: Bool) -> AnyPublisher<ExchangeRates, ApiError>
    func refreshData() -> AnyPublisher<Bool, Never>
}

class ConverterStore: Store {
    private let apiService: ApiService
    private let cacheService: CacheService
    private let ratesFileName = "rates"

    init(apiService: ApiService, cacheService: CacheService) {
        self.apiService = apiService
        self.cacheService = cacheService
    }

    func fetchData(_ forceUpdate: Bool) -> AnyPublisher<ExchangeRates, ApiError> {
        let getData: (String) -> AnyPublisher<ExchangeRates?, Never> = cacheService.getData

        return getData(ratesFileName)
            .setFailureType(to: ApiError.self)
            .flatMap { exchangeRates -> AnyPublisher<ExchangeRates, ApiError> in
                if let exchangeRates = exchangeRates {
                    let currentDate = Date().currentDate

                    if exchangeRates.date == currentDate && !forceUpdate {
                        NSLog("Data retrieved from cache.")
                        return Just(exchangeRates).setFailureType(to: ApiError.self).eraseToAnyPublisher()
                    }
                }

                return self.getDataFromServer()
        }
        .handleEvents(receiveSubscription: { _ in NSLog("Fetching data...") })
        .eraseToAnyPublisher()
    }

    func refreshData() -> AnyPublisher<Bool, Never> {
        let getData: (String) -> AnyPublisher<ExchangeRates?, Never> = cacheService.getData

        return getData(ratesFileName)
            .flatMap { exchangeRates -> AnyPublisher<Bool, Never> in
                if let exchangeRates = exchangeRates {
                    let currentDate = Date().currentDate

                    if exchangeRates.date == currentDate {
                        return Just(false).eraseToAnyPublisher()
                    }
                }

                return self.getDataFromServer().map { _ in true }.catch { _ in Just(false) }.eraseToAnyPublisher()
        }
        .handleEvents(receiveSubscription: { _ in NSLog("Refreshing data...") })
        .eraseToAnyPublisher()
    }

    private func getDataFromServer() -> AnyPublisher<ExchangeRates, ApiError> {
        let symbols = getSymbolsFromServer()
        let rates = getExchangeRatesFromServer()

        let exchangeRates = rates.combineLatest(symbols)
            .tryMap { self.parseRates(ratesResponse: $0, symbolsResponse: $1)! }
            .mapError { _ in ApiError.other }
            .share()

        let ratesToCache = exchangeRates
            .encode(encoder: JSONEncoder())
            .flatMap { self.cacheService.cacheData($0, to: self.ratesFileName).setFailureType(to: Error.self) }
            .mapError { _ in ApiError.other }

        let ratesToReturn = exchangeRates.map { $0 }

        return ratesToCache
            .combineLatest(ratesToReturn)
            .map { _, rates in rates }
            .eraseToAnyPublisher()
    }

    private func getSymbolsFromServer() -> AnyPublisher<SymbolsResponse, ApiError> {
        return apiService.getSymbols()
            .flatMap { self.validateResponse($0) }
            .eraseToAnyPublisher()
    }

    private func getExchangeRatesFromServer() -> AnyPublisher<LatestRatesResponse, ApiError> {
        return apiService.getLatestExchangeRates()
            .flatMap { self.validateResponse($0) }
            .eraseToAnyPublisher()
    }

    private func validateResponse<T: Response>(_ response: T) -> AnyPublisher<T, ApiError> {
        return Just(response)
            .tryMap { response in
                if let responseError = response.error {
                    NSLog("ApiError returned from API: \(responseError.info).")
                    throw ApiError.apiError
                }

                return response
            }
            .mapError { $0 as! ApiError }
            .eraseToAnyPublisher()
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
