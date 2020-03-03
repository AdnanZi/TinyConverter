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

    let symbolsResponse = SymbolsResponse(success: true, error: nil, symbols: ["AED": "United Arab Emirates Dirham", "AFN": "Afghan Afghani", "ALL": "Albanian Lek", "AMD": "Armenian Dram", "ANG": "Netherlands Antillean Guilder", "AOA": "Angolan Kwanza", "ARS": "Argentine Peso", "AUD": "Australian Dollar", "AWG": "Aruban Florin", "EUR": "Euro", "USD": "United States Dollar"])

    let exchangeRatesResponse = LatestRatesResponse(success: true,
                                                    error: nil,
                                                    timestamp: 1563038045,
                                                    base: "EUR",
                                                    date: "2019-07-13",
                                                    rates: ["AED": 4.14602, "AFN": 90.643209, "ALL": 122.248234, "AMD": 538.053473, "ANG": 2.009294, "AOA": 390.467138, "ARS": 46.877482, "AUD": 1.607685, "AWG": 2.031752, "EUR": 1, "USD": 1.128751])

    let rates = [
        ExchangeRate(code: "AED", name: "United Arab Emirates Dirham", value: 4.14602),
        ExchangeRate(code: "AFN", name: "Afghan Afghani", value: 90.643209),
        ExchangeRate(code: "ALL", name: "Albanian Lek", value: 122.248234),
        ExchangeRate(code: "AMD", name: "Armenian Dram", value: 538.053473),
        ExchangeRate(code: "ANG", name: "Netherlands Antillean Guilder", value: 2.009294),
        ExchangeRate(code: "AOA", name: "Angolan Kwanza", value: 390.467138),
        ExchangeRate(code: "ARS", name: "Argentine Peso", value: 46.877482),
        ExchangeRate(code: "AUD", name: "Australian Dollar", value: 1.607685),
        ExchangeRate(code: "AWG", name: "Aruban Florin", value: 2.031752),
        ExchangeRate(code: "EUR", name: "Euro", value: 1),
        ExchangeRate(code: "USD", name: "United States Dollar", value: 1.128751)
    ]

    var exchangeRates: ExchangeRates {
        return ExchangeRates(baseCurrency: "EUR", date: Date().currentDate, rates: rates)
    }

    var exchangeRatesOld: ExchangeRates {
        return ExchangeRates(baseCurrency: "EUR", date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, rates: rates)
    }

    func testFetchDataFromServer_NoError() {
        // Arrange
        let apiService = MockApiService(symbolsResponse, exchangeRatesResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "NoError")
        var resultError: Error?

        // Act
        store.fetchData(false) { _, error in
            resultError = error

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNil(resultError)
    }

    func testFetchDataFromServer_ResultReturned() {
        // Arrange
        let apiService = MockApiService(symbolsResponse, exchangeRatesResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "Result")
        var resultData: ExchangeRates?

        // Act
        store.fetchData(false) { data, _ in
            resultData = data

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
        XCTAssert(resultData!.baseCurrency == exchangeRatesResponse.base!)
        XCTAssert(resultData!.rates.first!.code == exchangeRatesResponse.rates!.first!.key)
        XCTAssert(resultData!.date == Date.dateFromApiString(exchangeRatesResponse.date!))
    }

    func testFetchDataFromServer_ConnectionError() {
        // Arrange
        let apiService = MockApiService(nil, nil, .noConnection)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "ConnError")
        var resultError: Error?

        // Act
        store.fetchData(false) { _, error in
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

        let apiService = MockApiService(symbolsResponse, exchangeRatesErrorResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "ApiError")
        var resultError: Error?

        // Act
        store.fetchData(false) { _, error in
            resultError = error

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssert(resultError! == .apiError)
    }

    func testFetchDataFromServer_SymbolsResponseNilError() {
        // Arrange
        let apiService = MockApiService(nil, exchangeRatesResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "OtherError")
        var resultError: Error?

        // Act
        store.fetchData(false) { _, error in
            resultError = error

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssert(resultError! == .other)
    }

    func testFetchDataFromServer_RatesResponseNilError() {
        // Arrange
        let apiService = MockApiService(symbolsResponse, nil, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "OtqqherError2")
        var resultError: Error?

        // Act
        store.fetchData(false) { _, error in
            resultError = error

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssert(resultError! == .other)
    }

    func testFetchDataFromServer_ErrorButReturnedFromCache() {
        // Arrange
        let apiService = MockApiService(nil, nil, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRatesOld)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "ErrorCache")
        var resultData: ExchangeRates?

        // Act
        store.fetchData(false) { data, _ in
            resultData = data

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
    }

    func testFetchDataFromCache() {
        // Arrange
        let apiService = MockApiService(nil, nil, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRates)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "Cache")
        var resultData: ExchangeRates?

        // Act
        store.fetchData(false) { data, _ in
            resultData = data

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
        XCTAssert(resultData!.baseCurrency == exchangeRates.baseCurrency)
        XCTAssert(resultData!.rates.first { r in r.code == "AED" }!.value == exchangeRates.rates.first { r in r.code == "AED" }!.value)
        XCTAssert(resultData!.date == exchangeRates.date)
    }

    func testForceUpdate() {
        // Arrange
        let todaysExchangeRatesResponse = LatestRatesResponse(success: exchangeRatesResponse.success, error: exchangeRatesResponse.error, timestamp: exchangeRatesResponse.timestamp, base: exchangeRatesResponse.base, date: Date().dateStringApi, rates: exchangeRatesResponse.rates)

        let apiService = MockApiService(symbolsResponse, todaysExchangeRatesResponse, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRates)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "ForceUpdate")
        var resultData: ExchangeRates?

        // Act
        store.fetchData(true) { data, _ in
            resultData = data

            expectation.fulfill()
        }

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
        XCTAssert(resultData!.baseCurrency == exchangeRates.baseCurrency)
        XCTAssert(resultData!.rates.first { r in r.code == "AED" }!.value == exchangeRates.rates.first { r in r.code == "AED" }!.value)
        XCTAssert(resultData!.date ==  Date.dateFromApiString(todaysExchangeRatesResponse.date!))
    }

    func testRefreshDataNotRefreshed() {
        // Arrange
        let apiService = MockApiService(nil, nil, nil)
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
        let apiService = MockApiService(symbolsResponse, exchangeRatesResponse, nil)
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
    let symbolsResponse: SymbolsResponse?
    let ratesResponse: LatestRatesResponse?
    let error: Error?

    init(_ symbolsResponse: SymbolsResponse?, _ ratesResponse: LatestRatesResponse?, _ error: Error?) {
        self.symbolsResponse = symbolsResponse
        self.ratesResponse = ratesResponse
        self.error = error
    }

    func getSymbols(completionHandler: @escaping (SymbolsResponse?, Error?) -> Void) {
        completionHandler(symbolsResponse, error)
    }

    func getLatestExchangeRates(completionHandler: @escaping (LatestRatesResponse?, Error?) -> Void) {
        completionHandler(ratesResponse, error)
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
