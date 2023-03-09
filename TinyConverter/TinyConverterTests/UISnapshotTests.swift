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

    func testConverterViewControllerContents() async throws {
        try await testViewControllerContents(viewController: getConverterController())
    }

    func testSettingsViewControllerContents() async throws {
        try await testViewControllerContents(viewController: getSettingsController())
    }

    func testUpdateIntervalViewControllerContents() async throws {
        try await testViewControllerContents(viewController: getUpdateIntervalController())
    }

    @MainActor
    private func testViewControllerContents(viewController: UIViewController) async throws {
        viewController.loadView()
        viewController.viewDidLoad()
        viewController.viewWillAppear(false)

        // Wait until the view gets populated
        try await Task.sleep(nanoseconds: 2000000000)

        FBSnapshotVerifyView(viewController.view)
    }

    private func getConverterController() -> ConverterViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let store = ConverterStore(apiService: MockApiService(TestData.symbolsResponse, TestData.exchangeRatesResponse, nil), cacheService: MockCacheService(cachedItem: TestData.exchangeRates))
        return storyboard.instantiateViewController(identifier: "converterViewController") { coder in
            ConverterViewController(coder: coder, viewModel: ConverterViewModel(store: store, configuration: StandardConfiguration()))
        }
    }

    private func getSettingsController() -> SettingsViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(identifier: "settingsViewController") { coder in
            SettingsViewController(coder: coder, viewModel: SettingsViewModel(configuration: StandardConfiguration()))
        }
    }

    private func getUpdateIntervalController() -> UpdateIntervalViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(identifier: "updateIntervalViewController") { coder in
            UpdateIntervalViewController(coder: coder, viewModel: UpdateIntervalViewModel(configuration: StandardConfiguration()))
        }
    }
}
