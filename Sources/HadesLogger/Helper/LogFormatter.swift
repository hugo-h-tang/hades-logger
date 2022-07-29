//
//  LogFormatter.swift
//  
//
//  Created by Hugo L on 2022/7/27.
//

import Foundation
import Logging

protocol LogFormatter {
    func format(_ log: String, level: Logger.Level) -> String
}
