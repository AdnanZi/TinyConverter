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
            .flatMap { [unowned self] exchangeRates -> AnyPublisher<ExchangeRates, ApiError> in
                if let exchangeRates {
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
            .flatMap { [unowned self] exchangeRates -> AnyPublisher<Bool, Never> in
                if let exchangeRates {
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

        return rates.combineLatest(symbols)
            .tryMap(parseRates)
            .mapError { ($0 as? ApiError) ?? ApiError.other }
            .flatMap(cacheRates)
            .eraseToAnyPublisher()
    }

    private func getSymbolsFromServer() -> AnyPublisher<SymbolsResponse, ApiError> {
        return apiService.getSymbols()
            .flatMap(validateResponse)
            .eraseToAnyPublisher()
    }

    private func getExchangeRatesFromServer() -> AnyPublisher<LatestRatesResponse, ApiError> {
        return apiService.getLatestExchangeRates()
            .flatMap(validateResponse)
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

    private func parseRates(ratesResponse: LatestRatesResponse, symbolsResponse: SymbolsResponse) throws -> ExchangeRates {
        guard let baseCurrency = ratesResponse.base, let dateString = ratesResponse.date, let rates = ratesResponse.rates, let symbols = symbolsResponse.symbols else {
            NSLog("Rates object missing required fields.")
            throw ApiError.other
        }

        guard let date = Date.dateFromApiString(dateString) else {
            NSLog("Couldn't convert provided date: \(dateString)")
            throw ApiError.other
        }

        let fullRates = rates.map { key, value in ExchangeRate(code: key, name: symbols[key]!, value: value) }

        return ExchangeRates(baseCurrency: baseCurrency, date: date, rates: fullRates)
    }

    private func cacheRates(_ exchangeRates: ExchangeRates) -> AnyPublisher<ExchangeRates, ApiError> {
        Just(exchangeRates)
            .encode(encoder: JSONEncoder())
            .map { [unowned self] in
                _ = self.cacheService.cacheData($0, to: self.ratesFileName)
            }
            .mapError { ($0 as? ApiError) ?? ApiError.other }
            .map { exchangeRates }
            .eraseToAnyPublisher()
    }
}
