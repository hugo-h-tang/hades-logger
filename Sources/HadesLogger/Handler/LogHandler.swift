//
//  LogHandler.swift
//  
//
//  Created by Hugo L on 2022/7/27.
//

import Foundation
import Logging

protocol LogHandler: Logging.LogHandler {
    var loggerQueue: DispatchQueue? { get set }
}

extension LogHandler {
    func log(level: Logging.Logger.Level, message: Logging.Logger.Message, metadata: Logging.Logger.Metadata?, file: String, function: String, line: UInt) {}
}
