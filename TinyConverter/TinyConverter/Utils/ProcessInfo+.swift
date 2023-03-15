//
//  ProcessInfo+.swift
//  TinyConverter
//
//  Created by Zildzic, Adnan on 15.03.23.
//  Copyright © 2023 Adnan Zildzic. All rights reserved.
//

import Foundation

extension ProcessInfo {
    var runningTests: Bool {
        environment["RUNNING_TESTS"] != nil
    }
}
