//
//  Symbols.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 07.09.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

struct SymbolsResponse: Codable {
    let success: Bool
    let error: ErrorResponse?
    let symbols: [String: String]
}
