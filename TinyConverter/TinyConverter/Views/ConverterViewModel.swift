//
//  ConverterViewModel.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation
import Combine

class ConverterViewModel: NSObject {
    private var cancellable = Set<AnyCancellable>()

    @Published private var storedExchangeRates: ExchangeRates?
    @Published private(set) var exchangeRates = [ExchangeRate]()
    @Published var latestUpdateDate: String? = ""

    @Published var baseCurrency: String? = .eur
    @Published var targetCurrency: String? = .usd

    @Published var baseAmount: String? = ""
    @Published var targetAmount: String? = ""

    let spinnerPublisher = PassthroughSubject<Bool, Never>()
    let alertPublisher = PassthroughSubject<Alert, Never>()

    // MARK: Obsolete
    private(set) var exchangeRatesOld = [ExchangeRate]()
    @objc dynamic var latestUpdateDateOld: String? = ""

    @objc dynamic var baseCurrencyOld: String? = .eur {
        didSet {
            if (oldValue == baseCurrencyOld) {
                return
            }

            baseAmountOld = calcuateBaseAmount()
            baseAmountEntered = baseAmountOld!
        }
    }

    @objc dynamic var targetCurrencyOld: String? = .usd {
        didSet {
            if (oldValue == targetCurrencyOld) {
                return
            }

            targetAmountOld = calculateTargetAmount()
            targetAmountEntered = targetAmountOld!
        }
    }

    @objc dynamic var baseAmountOld: String? = ""
    var baseAmountEntered: String = "" {
        didSet {
            targetAmountOld = calculateTargetAmount()
        }
    }

    @objc dynamic var targetAmountOld: String? = ""
    var targetAmountEntered: String = "" {
        didSet {
            baseAmountOld = calcuateBaseAmount()
        }
    }

    @objc dynamic var showSpinner = false
    @objc dynamic var alert: Alert?

    private let store: Store
    private let configuration: Configuration

    init(store: Store, configuration: Configuration) {
        self.store = store
        self.configuration = configuration

        super.init() // Needed for NSObject - remove

        setupSubscriptions()
    }

    private func setupSubscriptions() {
        $storedExchangeRates
            .filter { $0 != nil }
            .map { $0!.rates.sorted { $0.code < $1.code } }
            .assign(to: \.exchangeRates, on: self)
            .store(in: &cancellable)

        $storedExchangeRates
            .filter { $0 != nil }
            .map { $0!.date.dateString }
            .assign(to: \.latestUpdateDate, on: self)
            .store(in: &cancellable)

        $exchangeRates
            .filter { $0.count != 0 }
            .flatMap {
                Just($0.first { $0.code == .eur }?.code ?? $0.first!.code)
            }
            .assign(to: \.baseCurrency, on: self)
            .store(in: &cancellable)

        $exchangeRates
            .filter { $0.count != 0 }
            .flatMap {
                Just($0.first { $0.code == .usd }?.code ?? $0.first!.code)
            }
            .assign(to: \.targetCurrency, on: self)
            .store(in: &cancellable)

        $baseCurrency
            .removeDuplicates()
            .map { [weak self] _ in
                self?.calcuateBaseAmount()
            }
            .assign(to: \.baseAmount, on: self)
            .store(in: &cancellable)

        $targetCurrency
            .removeDuplicates()
            .map { [weak self] _ in
                self?.calculateTargetAmount()
            }
            .assign(to: \.targetAmount, on: self)
            .store(in: &cancellable)

        $baseAmount
            .removeDuplicates()
            .map { [weak self] _ in
                self?.calculateTargetAmount()
            }
            .assign(to: \.targetAmount, on: self)
            .store(in: &cancellable)

        $targetAmount
            .removeDuplicates()
            .map { [weak self] _ in
                self?.calcuateBaseAmount()
            }
            .assign(to: \.baseAmount, on: self)
            .store(in: &cancellable)
    }

    private func calculateTargetValue(baseValue: String?, baseCurrency: String?, targetCurrency: String?) -> String {
        guard let baseValue = baseValue, let multiplier = Double(baseValue),
            let baseCurrency = baseCurrency, let targetCurrency = targetCurrency,
            let baseCurrencyValue = exchangeRatesOld.first(where: { $0.code == baseCurrency })?.value, let targetCurrencyValue = exchangeRatesOld.first(where: { $0.code == targetCurrency })?.value else {
            return ""
        }

        let targetValue = multiplier * (targetCurrencyValue/baseCurrencyValue)

        return String(format: "%.2f", round(targetValue*100)/100)
    }

    private func calculateTargetAmount() -> String {
        return calculateTargetValue(baseValue: baseAmountEntered, baseCurrency: baseCurrencyOld, targetCurrency: targetCurrencyOld)
    }

    private func calcuateBaseAmount() -> String {
        return calculateTargetValue(baseValue: targetAmountEntered, baseCurrency: targetCurrencyOld, targetCurrency: baseCurrencyOld)
    }
}

extension ConverterViewModel {
    func fetchData() {
        store.fetchData(configuration.updateOnStart)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.spinnerPublisher.send(true)
            }, receiveOutput: { [weak self] _ in
                self?.spinnerPublisher.send(false)
            }, receiveCancel: { [weak self] in
                self?.spinnerPublisher.send(false)
            })
            .map { $0 as ExchangeRates? }
            .mapError { [weak self] error -> ApiError in
                if error == .noConnection {
                    self?.alertPublisher.send(Alert(alertTitle: .noConnectionAlertTitle, alertText: .noConnectionAlertText))
                }
                return error
            }
            .replaceError(with: nil)
            .assign(to: \.storedExchangeRates, on: self)
            .store(in: &cancellable)
    }

    func fetchDataOld() {
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
                self.exchangeRatesOld = storedExchangeRates.rates.sorted { $0.code < $1.code }
                self.latestUpdateDateOld = storedExchangeRates.date.dateString

                self.baseCurrencyOld = self.exchangeRatesOld.first { $0.code == .eur }?.code ?? self.exchangeRatesOld.first!.code
                self.targetCurrencyOld = self.exchangeRatesOld.first { $0.code == .usd }?.code ?? self.exchangeRatesOld.first!.code
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
