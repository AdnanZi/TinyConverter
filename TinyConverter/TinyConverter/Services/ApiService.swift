//
//  ApiService.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

protocol ApiService {
    func getSymbols(completionHandler: @escaping (Result<SymbolsResponse, Error>) -> Void)
    func getLatestExchangeRates(completionHandler: @escaping (Result<LatestRatesResponse, Error>) -> Void)
}

class FixerApiService: ApiService {
    private let apiKey = "b53418f0cda7fd7c937f4fd39851d5d1"
    private let serverHost = "http://data.fixer.io/api/"
    private let latestEndpoint = "latest"
    private let symbolsEndpoint = "symbols"

    private let connectionErrorCodes = [NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed, NSURLErrorNetworkConnectionLost]

    func getSymbols(completionHandler: @escaping (Result<SymbolsResponse, Error>) -> Void) {
        request(for: symbolsEndpoint, completionHandler: completionHandler)
    }

    func getLatestExchangeRates(completionHandler: @escaping (Result<LatestRatesResponse, Error>) -> Void) {
        request(for: latestEndpoint, completionHandler: completionHandler)
    }

    private func request<T: Decodable>(for endpoint: String, completionHandler: @escaping (Result<T, Error>) -> Void) {
        let url = getUrl(for: endpoint)

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {
                completionHandler(.failure(.other))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let jsonData = data else {
                if let error = error {
                    NSLog("Network data fetch done with error: \(error.localizedDescription).")

                    if self.connectionErrorCodes.contains(error._code) {
                        completionHandler(.failure(.noConnection))
                        return
                    }
                }

                completionHandler(.failure(.other))
                return
            }

            guard let response = try? JSONDecoder().decode(T.self, from: jsonData) else {
                NSLog("Error while deserializing json to \(T.self)")
                completionHandler(.failure(.other))
                return
            }

            NSLog("Network data fetch done with success, endpoint: \(endpoint).")
            completionHandler(.success(response))
        }

        NSLog("Started data fetch from endpoint: \(endpoint)")
        task.resume()
    }

    private func getUrl(for endpoint: String) -> URL {
        let urlString = "\(serverHost)\(endpoint)?access_key=\(apiKey)"
        return URL(string: urlString)!
    }
}
