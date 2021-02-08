//
//  ApiService.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation
import Combine

protocol ApiService {
    func getSymbols() -> AnyPublisher<SymbolsResponse, ApiError>
    func getLatestExchangeRates() -> AnyPublisher<LatestRatesResponse, ApiError>

    // MARK: Obsolete
    func getSymbols(completionHandler: @escaping (Result<SymbolsResponse, ApiError>) -> Void)
    func getLatestExchangeRates(completionHandler: @escaping (Result<LatestRatesResponse, ApiError>) -> Void)
}

class FixerApiService: ApiService {
    private let apiKey = "b53418f0cda7fd7c937f4fd39851d5d1"
    private let serverHost = "http://data.fixer.io/api/"
    private let latestEndpoint = "latest"
    private let symbolsEndpoint = "symbols"

    private let connectionErrorCodes = [NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed, NSURLErrorNetworkConnectionLost]

    func getSymbols() -> AnyPublisher<SymbolsResponse, ApiError> {
        return request(for: symbolsEndpoint)
    }

    func getLatestExchangeRates() -> AnyPublisher<LatestRatesResponse, ApiError> {
        return request(for: latestEndpoint)
    }

    private func request<T: Decodable>(for endpoint: String) -> AnyPublisher<T, ApiError> {
        return URLSession.shared.dataTaskPublisher(for: getUrl(for: endpoint))
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { [weak self] error in
                if let self = self, self.connectionErrorCodes.contains(error._code) {
                    return .noConnection
                }

                if error is DecodingError {
                    NSLog("ApiError while deserializing json to \(T.self)")
                }

                if error is URLError {
                    NSLog("Network data fetch done with error: \(error.localizedDescription).")
                }

                return .other
            }
            .handleEvents(receiveSubscription: { _ in NSLog("Started data fetch from endpoint: \(endpoint)") },
                          receiveOutput: { _ in NSLog("Network data fetch done with success, endpoint: \(endpoint).") })
            .eraseToAnyPublisher()
    }

    private func getUrl(for endpoint: String) -> URL {
        let urlString = "\(serverHost)\(endpoint)?access_key=\(apiKey)"
        return URL(string: urlString)!
    }

    func getSymbols(completionHandler: @escaping (Result<SymbolsResponse, ApiError>) -> Void) {
        request(for: symbolsEndpoint, completionHandler: completionHandler)
    }

    func getLatestExchangeRates(completionHandler: @escaping (Result<LatestRatesResponse, ApiError>) -> Void) {
        request(for: latestEndpoint, completionHandler: completionHandler)
    }

    private func request<T: Decodable>(for endpoint: String, completionHandler: @escaping (Result<T, ApiError>) -> Void) {
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
                NSLog("ApiError while deserializing json to \(T.self)")
                completionHandler(.failure(.other))
                return
            }

            NSLog("Network data fetch done with success, endpoint: \(endpoint).")
            completionHandler(.success(response))
        }

        NSLog("Started data fetch from endpoint: \(endpoint)")
        task.resume()
    }
}
