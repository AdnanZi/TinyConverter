//
//  TinyConverterTests.swift
//  TinyConverterTests
//
//  Created by Adnan Zildzic on 13.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import XCTest
import Combine
@testable import TinyConverter

class StoreTests: XCTestCase {
    let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    func testFetchDataFromServer_NoError() {
        // Arrange
        let apiService = MockApiService(TestData.symbolsResponse, TestData.exchangeRatesResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "NoError")
        var resultError: ApiError?

        // Act
        _ = store.fetchData(false)
            .sink(receiveCompletion: {
                if case .failure(let error) = $0 {
                    resultError = error
                }

                expectation.fulfill()
            }, receiveValue: { _ in })


        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNil(resultError)
    }

    func testFetchDataFromServer_ResultReturned() {
        // Arrange
        let exchangeRates = TestData.exchangeRatesResponse
        let apiService = MockApiService(TestData.symbolsResponse, exchangeRates, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "Result")
        var resultData: ExchangeRates?

        // Act
        _ = store.fetchData(false)
            .sink(receiveCompletion: { result in
                if case .failure = result {
                    XCTFail(.errorOnSuccess)
                }

                expectation.fulfill()
            }, receiveValue: {
                resultData = $0
            })

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
        XCTAssert(resultData!.baseCurrency == exchangeRates.base!)
        XCTAssert(resultData!.rates.first!.code == exchangeRates.rates!.first!.key)
        XCTAssert(resultData!.date == Date.dateFromApiString(exchangeRates.date!))
    }

    func testFetchDataFromServer_ConnectionError() {
        // Arrange
        let apiService = MockApiService(nil, nil, .noConnection)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "ConnError")
        var resultError: ApiError?

        // Act
        _ = store.fetchData(false)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    XCTFail(.successOnError)
                case .failure(let error):
                    resultError = error
                }

                expectation.fulfill()
            }, receiveValue: { _ in })

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertTrue(resultError! == .noConnection)
    }

    func testFetchDataFromServer_ApiError() {
        // Arrange
        let exchangeRatesErrorResponse = LatestRatesResponse(success: false, error: ErrorResponse(code: 0, type: "some", info: "some error"), timestamp: nil, base: nil, date: nil, rates: nil)

        let apiService = MockApiService(TestData.symbolsResponse, exchangeRatesErrorResponse, nil)

        let store = ConverterStore(apiService: apiService, cacheService: MockCacheService<ExchangeRates>())

        let expectation = self.expectation(description: "ApiError")
        var resultError: ApiError?

        // Act
        _ = store.fetchData(false)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    XCTFail(.successOnError)
                case .failure(let error):
                    resultError = error
                }

                expectation.fulfill()
            }, receiveValue: { _ in })

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssert(resultError! == .apiError)
    }

    func testFetchDataFromCache() {
        // Arrange
        let exchangeRates = TestData.exchangeRates
        let apiService = MockApiService(nil, nil, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRates)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "Cache")
        var resultData: ExchangeRates?

        // Act
        _ = store.fetchData(false)
            .sink(receiveCompletion: {
                if case .failure = $0 {
                    XCTFail(.errorOnSuccess)
                }

                expectation.fulfill()
            }, receiveValue: {
                resultData = $0
            })

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertNotNil(resultData)
        XCTAssert(resultData!.baseCurrency == exchangeRates.baseCurrency)
        XCTAssert(resultData!.rates.first { r in r.code == "AED" }!.value == exchangeRates.rates.first { r in r.code == "AED" }!.value)
        XCTAssert(resultData!.date == exchangeRates.date)
    }

    func testForceUpdate() {
        // Arrange
        let todaysExchangeRatesResponse = LatestRatesResponse(success: TestData.exchangeRatesResponse.success, error: TestData.exchangeRatesResponse.error, timestamp: TestData.exchangeRatesResponse.timestamp, base: TestData.exchangeRatesResponse.base, date: Date().dateStringApi, rates: TestData.exchangeRatesResponse.rates)
        let exchangeRates = TestData.exchangeRates

        let apiService = MockApiService(TestData.symbolsResponse, todaysExchangeRatesResponse, nil)
        let cacheService = MockCacheService(cachedItem: exchangeRates)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "ForceUpdate")
        var resultData: ExchangeRates?

        // Act
        _ = store.fetchData(true)
            .sink(receiveCompletion: {
                if case .failure = $0 {
                    XCTFail(.errorOnSuccess)
                }

                expectation.fulfill()
            }, receiveValue: {
                resultData = $0
            })

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
        let cacheService = MockCacheService(cachedItem: TestData.exchangeRates)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "NotRefreshed")
        var refreshedResult: Bool?

        // Act
        _ = store.refreshData()
            .sink(receiveCompletion: {
                if case .failure = $0 {
                    XCTFail(.errorOnSuccess)
                }

                expectation.fulfill()
            }, receiveValue: {
                refreshedResult = $0
            })

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertFalse(refreshedResult!)
    }

    func testRefreshDataRefreshed() {
        // Arrange
        let apiService = MockApiService(TestData.symbolsResponse, TestData.exchangeRatesResponse, nil)
        let cacheService = MockCacheService(cachedItem: TestData.exchangeRatesOld)

        let store = ConverterStore(apiService: apiService, cacheService: cacheService)

        let expectation = self.expectation(description: "Refreshed")
        var refreshedResult: Bool?

        // Act
        _ = store.refreshData()
            .sink(receiveCompletion: {
                if case .failure = $0 {
                    XCTFail(.errorOnSuccess)
                }

                expectation.fulfill()
            }, receiveValue: {
                refreshedResult = $0
            })

        waitForExpectations(timeout: 2, handler: nil)

        // Assert
        XCTAssertTrue(refreshedResult!)
    }
}
