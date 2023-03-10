//
//  Mocks.swift
//  TinyConverterTests
//
//  Created by Zildzic, Adnan on 09.03.23.
//  Copyright © 2023 Adnan Zildzic. All rights reserved.
//

import Foundation
@testable import TinyConverter

class MockApiService: ApiService {
    let symbolsResponse: SymbolsResponse?
    let ratesResponse: LatestRatesResponse?
    let error: Error?

    init(_ symbolsResponse: SymbolsResponse?, _ ratesResponse: LatestRatesResponse?, _ error: Error?) {
        self.symbolsResponse = symbolsResponse
        self.ratesResponse = ratesResponse
        self.error = error
    }

    func getSymbols(completionHandler: @escaping (Result<SymbolsResponse, Error>) -> Void) {
        completionHandler(error != nil ? .failure(error!) : .success(symbolsResponse!))
    }

    func getLatestExchangeRates(completionHandler: @escaping (Result<LatestRatesResponse, Error>) -> Void) {
        completionHandler(error != nil ? .failure(error!) : .success(ratesResponse!))
    }
}

class MockCacheService<T: Decodable>: CacheService {
    private let cachedItem: T?

    init(cachedItem: T? = nil) {
        self.cachedItem = cachedItem
    }

    func getData<T>(from fileName: String) -> T? where T : Decodable {
        return cachedItem as! T?
    }

    func cacheData(_ jsonData: Data, to fileName: String) { }
}
