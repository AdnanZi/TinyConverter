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
}

class FileCacheService: CacheService {
    func getData<T:Decodable>(from fileName: String) -> AnyPublisher<T?, Never> {
        Deferred {
            return Future<Data?, Never> { [unowned self] promise in
                return promise(.success(try? Data(contentsOf: self.storeLocation(fileName))))
            }
        }
        .flatMap { data -> AnyPublisher<T? , Never> in
            guard let data = data else {
                return Just(nil)
                    .eraseToAnyPublisher()
            }

            return Just(data)
                .decode(type: T.self, decoder: JSONDecoder())
                .map { $0 as T? }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }

    func cacheData(_ jsonData: Data, to fileName: String) -> AnyPublisher<Void, Never> {
        return Deferred {
            return Future<Void?, Never> { [unowned self] promise in
                return promise(.success(try? jsonData.write(to: self.storeLocation(fileName))))
            }
        }
        .replaceNil(with: ())
        .eraseToAnyPublisher()
    }

    private func storeLocation(_ fileName: String) -> URL {
        let libraryDirectory = try! FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return libraryDirectory.appendingPathComponent("\(fileName).json")
    }
}
