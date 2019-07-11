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

    @objc dynamic var baseCurrency: String? = "EUR" {
        didSet {
            if (oldValue == baseCurrency) {
                return
            }

            baseAmount = calculateTargetValue(baseValue: targetAmountEntered, baseCurrency: targetCurrency, targetCurrency: baseCurrency)
            baseAmountEntered = baseAmount!
        }
    }

    @objc dynamic var targetCurrency: String? = "USD" {
        didSet {
            if (oldValue == targetCurrency) {
                return
            }

            targetAmount = calculateTargetValue(baseValue: baseAmountEntered, baseCurrency: baseCurrency, targetCurrency: targetCurrency)
            targetAmountEntered = targetAmount!
        }
    }

    @objc dynamic var baseAmount: String? = ""
    var baseAmountEntered: String = "" {
        didSet {
            targetAmount = calculateTargetValue(baseValue: baseAmountEntered, baseCurrency: baseCurrency, targetCurrency: targetCurrency)
        }
    }

    @objc dynamic var targetAmount: String? = ""
    var targetAmountEntered: String = "" {
        didSet {
            baseAmount = calculateTargetValue(baseValue: targetAmountEntered, baseCurrency: targetCurrency, targetCurrency: baseCurrency)
        }
    }

    @objc dynamic var showSpinner = false;

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateStartedNotification), name: Store.updateStartedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateDoneNotification(_:)), name: Store.updateDoneNotification, object: nil)

        if exchangeRates.isEmpty {
            Store.shared.getDataFromServer()
        }
    }

    @objc private func handleUpdateStartedNotification() {
        showSpinner = true
    }

    @objc private func handleUpdateDoneNotification(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                return
            }

            strongSelf.showSpinner = false

            guard let storedExchangeRates = notification.object as? ExchangeRates else {
                return
            }

            strongSelf.exchangeRates = storedExchangeRates.rates
            strongSelf.symbols = [String](strongSelf.exchangeRates.keys).sorted { $0 < $1 }

            strongSelf.baseCurrency = strongSelf.symbols.filter { $0 == "EUR" }.first ?? strongSelf.symbols[0]
            strongSelf.targetCurrency = strongSelf.symbols.filter { $0 == "USD" }.first ?? strongSelf.symbols[0]
        }
    }

    private func calculateTargetValue(baseValue: String?, baseCurrency: String?, targetCurrency: String?) -> String {
        guard let baseValue = baseValue, let multiplier = Double(baseValue),
            let baseCurrency = baseCurrency, let targetCurrency = targetCurrency,
            let baseCurrencyValue = exchangeRates[baseCurrency], let targetCurrencyValue = exchangeRates[targetCurrency] else {
            return "";
        }

        let targetValue = multiplier * (targetCurrencyValue/baseCurrencyValue)

        return String(format: "%.2f", targetValue)
    }
}
