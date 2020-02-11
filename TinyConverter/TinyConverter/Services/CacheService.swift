//
//  CacheStore.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 07.09.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

protocol CacheService {
    func getData<T: Decodable>(from fileName: String) -> T?
    func cacheData(_ jsonData: Data, to fileName: String)
}

class CacheServiceImpl: CacheService {
    func getData<T: Decodable>(from fileName: String) -> T? {
        guard let cachedData = try? Data(contentsOf: storeLocation(fileName)) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: cachedData)
    }

    func cacheData(_ jsonData: Data, to fileName: String) {
        try? jsonData.write(to: storeLocation(fileName))
    }

    private func storeLocation(_ fileName: String) -> URL {
        let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return libraryDirectory.appendingPathComponent("\(fileName).json")
    }
}
