//
//  ConverterViewModel.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

class ConverterViewModel: NSObject {
    private(set) var exchangeRates = [ExchangeRate]()
    @objc dynamic var latestUpdateDate: String? = ""

    @objc dynamic var baseCurrency: String? = .eur {
        didSet {
            if (oldValue == baseCurrency) {
                return
            }

            baseAmount = calcuateBaseAmount()
            baseAmountEntered = baseAmount!
        }
    }

    @objc dynamic var targetCurrency: String? = .usd {
        didSet {
            if (oldValue == targetCurrency) {
                return
            }

            targetAmount = calculateTargetAmount()
            targetAmountEntered = targetAmount!
        }
    }

    @objc dynamic var baseAmount: String? = ""
    var baseAmountEntered: String = "" {
        didSet {
            targetAmount = calculateTargetAmount()
        }
    }

    @objc dynamic var targetAmount: String? = ""
    var targetAmountEntered: String = "" {
        didSet {
            baseAmount = calcuateBaseAmount()
        }
    }

    @objc dynamic var showSpinner = false
    @objc dynamic var alert: Alert?

    private let store: Store
    private let configuration: Configuration

    init(store: Store, configuration: Configuration) {
        self.store = store
        self.configuration = configuration
    }

    private func calculateTargetValue(baseValue: String?, baseCurrency: String?, targetCurrency: String?) -> String {
        guard let baseValue = baseValue, let multiplier = Double(baseValue),
            let baseCurrency = baseCurrency, let targetCurrency = targetCurrency,
            let baseCurrencyValue = exchangeRates.first(where: { $0.code == baseCurrency })?.value, let targetCurrencyValue = exchangeRates.first(where: { $0.code == targetCurrency })?.value else {
            return ""
        }

        let targetValue = multiplier * (targetCurrencyValue/baseCurrencyValue)

        return String(format: "%.2f", round(targetValue*100)/100)
    }

    private func calculateTargetAmount() -> String {
        return calculateTargetValue(baseValue: baseAmountEntered, baseCurrency: baseCurrency, targetCurrency: targetCurrency)
    }

    private func calcuateBaseAmount() -> String {
        return calculateTargetValue(baseValue: targetAmountEntered, baseCurrency: targetCurrency, targetCurrency: baseCurrency)
    }
}

extension ConverterViewModel {
    func fetchData() {
        store.fetchData(configuration.updateOnStart, dataFetchedHandler)

        showSpinner = true
    }

    private func dataFetchedHandler(_ result: Result<ExchangeRates, ApiError>) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            self.showSpinner = false

            switch result {
            case .success(let storedExchangeRates):
                self.exchangeRates = storedExchangeRates.rates.sorted { $0.code < $1.code }
                self.latestUpdateDate = storedExchangeRates.date.dateString

                self.baseCurrency = self.exchangeRates.first { $0.code == .eur }?.code ?? self.exchangeRates.first!.code
                self.targetCurrency = self.exchangeRates.first { $0.code == .usd }?.code ?? self.exchangeRates.first!.code
            case .failure(let error):
                if error == .noConnection {
                    self.alert = Alert(alertTitle: .noConnectionAlertTitle, alertText: .noConnectionAlertText)
                }
            }
        }
    }
}

fileprivate extension String {
    static let eur = "EUR"
    static let usd = "USD"
    static let noConnectionAlertTitle = "No internet connection"
    static let noConnectionAlertText = "Internet connection is not available or is bad. Exchange rates might be obsolete. Do you want to try again?"
}
