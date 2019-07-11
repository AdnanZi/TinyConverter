//
//  ConverterViewModel.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 10.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

class ConverterViewModel: NSObject {
    let symbols = ["EUR", "USD", "GBP"]
    @objc dynamic var baseCurrency: String? = "EUR"
    @objc dynamic var targetCurrency: String? = "USD"
}
