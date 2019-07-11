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
    var exchangeRates = [String: Double]()

    @objc dynamic var baseCurrency: String? = "EUR"
    @objc dynamic var targetCurrency: String? = "USD"
    @objc dynamic var showSpinner = false;

    let store = Store.shared

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateStartedNotification), name: Store.updateStartedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateDoneNotification(_:)), name: Store.updateDoneNotification, object: nil)

        if exchangeRates.isEmpty {
            store.getDataFromServer()
        }
    }

    @objc func handleUpdateStartedNotification() {
        showSpinner = true
    }

    @objc func handleUpdateDoneNotification(_ notification: Notification) {
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
}
