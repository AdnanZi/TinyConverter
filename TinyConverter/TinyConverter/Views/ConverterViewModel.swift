//
//  ConverterViewModel.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation
import Combine

class ConverterViewModel {
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

    private let store: Store
    private let configuration: Configuration

    init(store: Store, configuration: Configuration) {
        self.store = store
        self.configuration = configuration

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
            let baseCurrencyValue = exchangeRates.first(where: { $0.code == baseCurrency })?.value, let targetCurrencyValue = exchangeRates.first(where: { $0.code == targetCurrency })?.value else {
            return ""
        }

        let targetValue = multiplier * (targetCurrencyValue/baseCurrencyValue)

        return String(format: "%.2f", round(targetValue*100)/100)
    }

    private func calculateTargetAmount() -> String {
        return calculateTargetValue(baseValue: baseAmount, baseCurrency: baseCurrency, targetCurrency: targetCurrency)
    }

    private func calcuateBaseAmount() -> String {
        return calculateTargetValue(baseValue: targetAmount, baseCurrency: targetCurrency, targetCurrency: baseCurrency)
    }
}

extension ConverterViewModel {
    func fetchData() -> AnyPublisher<Void, Never> {
        store.fetchData(configuration.updateOnStart)
            .handleEvents(receiveSubscription: { [weak self] _ in
                self?.spinnerPublisher.send(true)
            }, receiveOutput: { [weak self] _ in
                self?.spinnerPublisher.send(false)
            }, receiveCancel: { [weak self] in
                self?.spinnerPublisher.send(false)
            })
            .mapError { [weak self] error -> ApiError in
                self?.spinnerPublisher.send(false)

                if error == .noConnection {
                    self?.alertPublisher.send(Alert(alertTitle: .noConnectionAlertTitle, alertText: .noConnectionAlertText))
                }
                return error
            }
            .map { [weak self] exchageRates in
                self?.storedExchangeRates = exchageRates
                return ()
            }
            .replaceError(with: ())
            .eraseToAnyPublisher()
    }
}

fileprivate extension String {
    static let eur = "EUR"
    static let usd = "USD"
    static let noConnectionAlertTitle = "No internet connection"
    static let noConnectionAlertText = "Internet connection is not available or is bad. Exchange rates might be obsolete. Do you want to try again?"
}
