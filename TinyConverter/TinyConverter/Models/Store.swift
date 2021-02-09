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
    // MARK: Obsolete
    func fetchData(_ forceUpdate: Bool, _ completionHandler: @escaping (Result<ExchangeRates, ApiError>) -> Void)
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

    // MARK: Obsolete
    func fetchData(_ forceUpdate: Bool, _ completionHandler: @escaping (Result<ExchangeRates, ApiError>) -> Void) {
        NSLog("Fetching data...")

        let exchangeRates: ExchangeRates? = cacheService.getData1(from: ratesFileName)

        if let exchangeRates = exchangeRates {
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

    // MARK: Obsolete
    func refreshData(_ completionHandler: @escaping (Bool) -> Void) {
        NSLog("Refreshing data...")

        if let exchangeRates: ExchangeRates = cacheService.getData1(from: ratesFileName) {
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

    //  MARK: Obsolete
    private func getDataFromServer(_ completionHandler: @escaping (Result<ExchangeRates, ApiError>) -> Void) {
        apiService.getSymbols { [weak self] result in
            guard let self = self else {
                completionHandler(.failure(.other))
                return
            }

            switch result {
            case .failure(let error):
                completionHandler(.failure(error))
            case .success(let symbolsResponse):
                self.getExchangeRates(symbolsResponse, completionHandler: completionHandler)
            }
        }
    }

    private func getExchangeRates(_ symbolsResponse: SymbolsResponse, completionHandler: @escaping (Result<ExchangeRates, ApiError>) -> Void) {
        apiService.getLatestExchangeRates { [weak self] result in
            guard let self = self else {
                completionHandler(.failure(.other))
                return
            }

            switch result {
            case .failure(let error):
                completionHandler(.failure(error))
            case .success(let ratesResponse):
                guard let exchangeRates = self.parseRates(ratesResponse: ratesResponse, symbolsResponse: symbolsResponse) else {
                    completionHandler(.failure(.other))
                    return
                }

                if let exchangeRatesJson = try? JSONEncoder().encode(exchangeRates) {
                    self.cacheService.cacheData1(exchangeRatesJson, to: self.ratesFileName)
                } else {
                    NSLog("Error while deserializing json form ExchangeRates. Data not saved to cache.")
                }

                completionHandler(.success(exchangeRates))
            }
        }
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
