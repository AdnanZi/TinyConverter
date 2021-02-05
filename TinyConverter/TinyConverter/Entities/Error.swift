//
//  Error.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
enum Error: Swift.Error {
    case noConnection
    case apiError
    case other
}

struct ErrorResponse: Codable {
    let code: Int
    let type: String
    let info: String
}
