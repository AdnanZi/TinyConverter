//
//  Alert.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 13.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import Foundation

@objc class Alert: NSObject {
    let alertTitle: String
    let alertText: String

    init(alertTitle: String, alertText: String) {
        self.alertTitle = alertTitle
        self.alertText = alertText
    }
}
