//
//  TinyConverterTests.swift
//  TinyConverterTests
//
//  Created by Adnan Zildzic on 13.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import XCTest
@testable import TinyConverter

class StoreTests: XCTestCase {
    let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    let exchangeRatesResponse = LatestRatesResponse(success: true,
                                                    error: nil,
                                                    timestamp: 1563038045,
                                                    base: "EUR",
                                                    date: "2019-07-13",
                                                    rates: ["AED": 4.14602, "AFN": 90.643209, "ALL": 122.248234, "AMD": 538.053473, "ANG": 2.009294, "AOA": 390.467138, "ARS": 46.877482, "AUD": 1.607685, "AWG": 2.031752, "EUR": 1, "USD": 1.128751])

    let exchangeRates = ExchangeRates(baseCurrency: "EUR", date: Date().currentDate, rates: ["AED": 4.14602, "AFN": 90.643209, "ALL": 122.248234, "AMD": 538.053473, "ANG": 2.009294, "AOA": 390.467138, "ARS": 46.877482, "AUD": 1.607685, "AWG": 2.031752, "EUR": 1, "USD": 1.128751])

    let exchangeRatesOld = ExchangeRates(baseCurrency: "EUR", date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, rates: ["AED": 4.14602, "AFN": 90.643209, "ALL": 122.248234, "AMD": 538.053473, "ANG": 2.009294, "AOA": 390.467138, "ARS": 46.877482, "AUD": 1.607685, "AWG": 2.031752, "EUR": 1, "USD": 1.128751])

    func testFetchDataFromServer_NoError() {
        // Arrange
        let apiService = MockApiService(exchangeRatesResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "NoError")
        var resultError: Error?

        // Act
        store.fetchData { _, error in
            resultError = error

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNil(resultError)
    }

    func testFetchDataFromServer_ResultReturned() {
        // Arrange
        let apiService = MockApiService(exchangeRatesResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "Result")
        var resultData: ExchangeRates?

        // Act
        store.fetchData { data, _ in
            resultData = data

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
        XCTAssert(resultData!.baseCurrency == exchangeRatesResponse.base!)
        XCTAssert(resultData!.rates.first!.key == exchangeRatesResponse.rates!.first!.key)
        XCTAssert(resultData!.date == Date.dateFromApiString(exchangeRatesResponse.date!))
    }

    func testFetchDataFromServer_ConnectionError() {
        // Arrange
        let apiService = MockApiService(nil, .noConnection)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "ConnError")
        var resultError: Error?

        // Act
        store.fetchData { _, error in
            resultError = error

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssert(resultError! == .noConnection)
    }

    func testFetchDataFromServer_ApiError() {
        // Arrange
        let exchangeRatesErrorResponse = LatestRatesResponse(success: false, error: ErrorResponse(code: 0, type: "some", info: "some error"), timestamp: nil, base: nil, date: nil, rates: nil)

        let apiService = MockApiService(exchangeRatesErrorResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "ApiError")
        var resultError: Error?

        // Act
        store.fetchData { _, error in
            resultError = error

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssert(resultError! == .apiError)
    }

    func testFetchDataFromServer_ErrorButReturnedFromCache() {
        // Arrange
        let apiService = MockApiService(nil, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRatesOld)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "ErrorCache")
        var resultData: ExchangeRates?

        // Act
        store.fetchData { data, _ in
            resultData = data

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
    }

    func testFetchDataFromCache() {
        // Arrange
        let apiService = MockApiService(nil, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRates)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "Cache")
        var resultData: ExchangeRates?

        // Act
        store.fetchData { data, _ in
            resultData = data

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
        XCTAssert(resultData!.baseCurrency == exchangeRates.baseCurrency)
        XCTAssert(resultData!.rates["AED"] == exchangeRates.rates["AED"])
        XCTAssert(resultData!.date == exchangeRates.date)
    }

    func testRefreshDataNotRefreshed() {
        // Arrange
        let apiService = MockApiService(nil, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRates)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "NotRefreshed")
        var refreshedResult: Bool?

        // Act
        store.refreshData { refreshed in
            refreshedResult = refreshed

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertFalse(refreshedResult!)
    }

    func testRefreshDataRefreshed() {
        // Arrange
        let apiService = MockApiService(exchangeRatesResponse, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRatesOld)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "Refreshed")
        var refreshedResult: Bool?

        // Act
        store.refreshData { refreshed in
            refreshedResult = refreshed

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertTrue(refreshedResult!)
    }
}

class MockApiService: ApiService {
    let response: LatestRatesResponse?
    let error: Error?

    init(_ response: LatestRatesResponse?, _ error: Error?) {
        self.response = response
        self.error = error
    }

    func getSymbols(completionHandler: @escaping (SymbolsResponse?, Error?) -> Void) {
        completionHandler(nil, nil) // TODO: Implement this
    }

    func getLatestExchangeRates(completionHandler: @escaping (LatestRatesResponse?, Error?) -> Void) {
        completionHandler(response, error)
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
