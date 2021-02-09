//
//  PropertyBinder.swift
//  TinyConverter
//
//  Created by Adnan Zildzic on 11.07.19.
//  Copyright © 2019 Adnan Zildzic. All rights reserved.
//
import UIKit

// MARK: Obsolete
extension NSObjectProtocol where Self: NSObject {
    func bind<Value, View>(_ keyPath: KeyPath<Self, Value>, to view: View, at property: ReferenceWritableKeyPath<View, Value>) -> NSKeyValueObservation {
        return observe(keyPath, options: [.initial, .new]) { _, change in
            guard let value = change.newValue else { return }

            view[keyPath: property] = value
        }
    }
}
