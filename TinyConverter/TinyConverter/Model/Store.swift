//
//  Store.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 11.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//

import Foundation

class Store {
    static let updateStartedNotification = Notification.Name("UpdateStarted")
    static let updateDoneNotification = Notification.Name("UpdateDone")

    private let apiKey = "b53418f0cda7fd7c937f4fd39851d5d1"
    private let serverHost = "http://data.fixer.io/api/"
    private let latestEndpoint = "latest"

    private var exchangeRates: ExchangeRates? = nil

    static let shared = Store()

    func getDataFromServer() {
        guard let url = getUrl(for: latestEndpoint) else {
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let jsonData = data else {
                // TODO: Handle errors
                return
            }

            guard let strongSelf = self else {
                return
            }

            var response: LatestRatesResponse? = nil

            do {
                response = try JSONDecoder().decode(LatestRatesResponse.self, from: jsonData)
            } catch {
                print(error)
            }

            if let response = response, response.error == nil { // TODO: Handle errors
                strongSelf.exchangeRates = strongSelf.parseRates(from: response)

                NotificationCenter.default.post(name: Store.updateDoneNotification, object: strongSelf.exchangeRates)
            }
        }

        NotificationCenter.default.post(name: Store.updateStartedNotification, object: nil)

        task.resume()
    }

    private func getUrl(for endpoint: String) -> URL? {
        let urlString = "\(serverHost)\(endpoint)?access_key=\(apiKey)"
        return URL(string: urlString)
    }

    private func parseRates(from response: LatestRatesResponse) -> ExchangeRates? {
        guard let baseCurrency = response.base, let dateString = response.date, let rates = response.rates else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = dateFormatter.date(from: dateString) else {
            return nil
        }

        return ExchangeRates(baseCurrency: baseCurrency, date: date, rates: rates)
    }
}
