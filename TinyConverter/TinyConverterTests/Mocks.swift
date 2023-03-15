//
//  Mocks.swift
//  TinyConverterTests
//
//  Created by Zildzic, Adnan on 09.03.23.
//  Copyright © 2023 Adnan Zildzic. All rights reserved.
//

import Foundation
import Combine
@testable import TinyConverter

class MockApiService: ApiService {
    let symbolsResponse: SymbolsResponse?
    let ratesResponse: LatestRatesResponse?
    let error: ApiError?

    init(_ symbolsResponse: SymbolsResponse?, _ ratesResponse: LatestRatesResponse?, _ error: ApiError?) {
        self.symbolsResponse = symbolsResponse
        self.ratesResponse = ratesResponse
        self.error = error
    }

    func getSymbols() -> AnyPublisher<SymbolsResponse, ApiError> {
        if error != nil {
            return Fail(error: error!).eraseToAnyPublisher()
        }

        return Just(symbolsResponse!).setFailureType(to: ApiError.self).eraseToAnyPublisher()
    }

    func getLatestExchangeRates() -> AnyPublisher<LatestRatesResponse, ApiError> {
        if error != nil {
            return Fail(error: error!).eraseToAnyPublisher()
        }

        return Just(ratesResponse!).setFailureType(to: ApiError.self).eraseToAnyPublisher()
    }
}

class MockCacheService<T: Decodable>: CacheService {
    private let cachedItem: T?

    init(cachedItem: T? = nil) {
        self.cachedItem = cachedItem
    }

    func getData<T>(from fileName: String) -> AnyPublisher<T?, Never> where T : Decodable {
        Just(cachedItem as! T?).eraseToAnyPublisher()
    }

    func cacheData(_ jsonData: Data, to fileName: String) -> AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}
