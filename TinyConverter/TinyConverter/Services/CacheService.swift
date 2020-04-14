//
//  CacheStore.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 07.09.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation
import Combine

protocol CacheService {
    func getData<T:Decodable>(from fileName: String) -> AnyPublisher<T?, Never>
    func cacheData(_ jsonData: Data, to fileName: String) -> AnyPublisher<Void, Never>

    // MARK: Obsolete
    func getData1<T: Decodable>(from fileName: String) -> T?
    func cacheData1(_ jsonData: Data, to fileName: String)
}

class FileCacheService: CacheService {
    func getData<T:Decodable>(from fileName: String) -> AnyPublisher<T?, Never> {
        return Just(try! Data(contentsOf: storeLocation(fileName)))
            .decode(type: T.self, decoder: JSONDecoder())
            .map { $0 as T? }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }

    func cacheData(_ jsonData: Data, to fileName: String) -> AnyPublisher<Void, Never> {
        Just(try! jsonData.write(to: storeLocation(fileName)))
            .replaceError(with: ())
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    private func storeLocation(_ fileName: String) -> URL {
        let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return libraryDirectory.appendingPathComponent("\(fileName).json")
    }

    // MARK: Obsolete
    func getData1<T: Decodable>(from fileName: String) -> T? {
        guard let cachedData = try? Data(contentsOf: storeLocation(fileName)) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: cachedData)
    }

    func cacheData1(_ jsonData: Data, to fileName: String) {
        try? jsonData.write(to: storeLocation(fileName))
    }
}
