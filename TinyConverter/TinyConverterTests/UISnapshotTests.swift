//
//  UISnapshotTests.swift
//  TinyConverterTests
//
//  Created by Zildzic, Adnan on 09.03.23.
//  Copyright © 2023 Adnan Zildzic. All rights reserved.
//

import iOSSnapshotTestCase
@testable import TinyConverter

final class UISnapshotTests: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()
        recordMode = false
    }

    @MainActor
    func testConverterViewControllerContents() async throws {
        let viewController = getConverterController()
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.viewWillAppear(false)

        // Wait until the view gets populated
        try await Task.sleep(nanoseconds: 2000000000)

        FBSnapshotVerifyView(viewController.view)
    }

    private func getConverterController() -> ConverterViewController {
        let store = ConverterStore(apiService: MockApiService(TestData.symbolsResponse, TestData.exchangeRatesResponse, nil), cacheService: MockCacheService(cachedItem: TestData.exchangeRates))
        return ConverterViewController(viewModel: ConverterViewModel(store: store, configuration: StandardConfiguration()))
    }
}
