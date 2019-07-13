//
//  ApiService.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

protocol ApiService {
    func getLatestExchangeRates(completionHandler: @escaping (LatestRatesResponse?, Error?) -> Void)
}

class FixerApiService: ApiService {
    private let apiKey = "b53418f0cda7fd7c937f4fd39851d5d1"
    private let serverHost = "http://data.fixer.io/api/"
    private let latestEndpoint = "latest"

    private let connectionErrorCodes = [NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed, NSURLErrorNetworkConnectionLost]

    func getLatestExchangeRates(completionHandler: @escaping (LatestRatesResponse?, Error?) -> Void) {
        let url = getUrl(for: latestEndpoint)

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let strongSelf = self else {
                completionHandler(nil, nil)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let jsonData = data else {
                if let error = error {
                    NSLog("Network data fetch done with error: \(error.localizedDescription).")

                    if strongSelf.connectionErrorCodes.contains(error._code) {
                        completionHandler(nil, .noConnection)
                        return
                    }
                }

                completionHandler(nil, .other)
                return
            }

            guard let response = try? JSONDecoder().decode(LatestRatesResponse.self, from: jsonData) else {
                NSLog("Error while deserializing json to LatestRatesResponse.")
                completionHandler(nil, .other)
                return
            }

            NSLog("Network data fetch done with success.")
            completionHandler(response, nil)
        }

        NSLog("Started data fetch...")
        task.resume()
    }

    private func getUrl(for endpoint: String) -> URL {
        let urlString = "\(serverHost)\(endpoint)?access_key=\(apiKey)"
        return URL(string: urlString)!
    }
}
