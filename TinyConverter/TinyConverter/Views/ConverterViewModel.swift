//
//  ConverterViewModel.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

class ConverterViewModel: NSObject {
    var symbols = [String]()
    private var exchangeRates = [String: Double]()

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
    @objc dynamic var alert: Alert? = nil

    private let store: Store

    init(store: Store? = nil) {
        self.store = store ?? ConverterStore.shared
    }

    private func calculateTargetValue(baseValue: String?, baseCurrency: String?, targetCurrency: String?) -> String {
        guard let baseValue = baseValue, let multiplier = Double(baseValue),
            let baseCurrency = baseCurrency, let targetCurrency = targetCurrency,
            let baseCurrencyValue = exchangeRates[baseCurrency], let targetCurrencyValue = exchangeRates[targetCurrency] else {
            return ""
        }

        let targetValue = multiplier * (targetCurrencyValue/baseCurrencyValue)

        return String(format: "%.2f", targetValue)
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
        store.fetchData(dataFetchedHandler)

        showSpinner = true
    }

    private func dataFetchedHandler(_ data: ExchangeRates?, _ error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.showSpinner = false

            guard let storedExchangeRates = data else {
                if error == .noConnection {
                    strongSelf.alert = Alert(alertTitle: .noConnectionAlertTitle, alertText: .noConnectionAlertText)
                }

                return
            }

            strongSelf.exchangeRates = storedExchangeRates.rates
            strongSelf.symbols = strongSelf.exchangeRates.keys.sorted { $0 < $1 }

            strongSelf.baseCurrency = strongSelf.symbols.filter { $0 == .eur }.first ?? strongSelf.symbols[0]
            strongSelf.targetCurrency = strongSelf.symbols.filter { $0 == .usd }.first ?? strongSelf.symbols[0]
        }
    }
}

fileprivate extension String {
    static let eur = "EUR"
    static let usd = "USD"
    static let noConnectionAlertTitle = "No internet connection"
    static let noConnectionAlertText = "Internet connection is not avilable or is bad. Exchange rates might be obsolete. Do you want to try again?"
}
