//
//  Response.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 07.09.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

protocol Response {
    var success: Bool { get }
    var error: ErrorResponse? { get }
}
