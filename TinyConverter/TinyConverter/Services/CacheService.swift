//
//  CacheStore.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 07.09.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

protocol CacheService {
    func getDataFromCache<T: Decodable>() -> T?
    func cacheData(_ jsonData: Data)
}

class CacheServiceImpl: CacheService {
    private let fileName: String

    private var storeLocation: URL {
        let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return libraryDirectory.appendingPathComponent("\(fileName).json")
    }

    init(fileName: String) {
        self.fileName = fileName
    }

    func getDataFromCache<T: Decodable>() -> T? {
        guard let cachedData = try? Data(contentsOf: storeLocation) else {
            return nil
        }

        return try? JSONDecoder().decode(T.self, from: cachedData)
    }

    func cacheData(_ jsonData: Data) {
        try? jsonData.write(to: storeLocation)
    }
}
