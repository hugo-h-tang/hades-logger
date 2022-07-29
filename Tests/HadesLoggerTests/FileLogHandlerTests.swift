//
//  FileLogHandlerTests.swift
//  
//
//  Created by Hugo L on 2022/7/28.
//

import XCTest

@testable import HadesLogger
@testable import Logging
class FileLogHandlerTests: XCTestCase {
    var fileLogHandler: FileLogHandler!
    var log: Logger!
    var queue: DispatchQueue!
    
    override func setUpWithError() throws {
        let label = "xyz.123.qqq"
        queue = DispatchQueue.init(label: label)
        var handler = ProxyLogHandler(loggerQueue: queue, logLevel: .debug, metadata: [:])
        fileLogHandler = FileLogHandler()
        fileLogHandler.bufferSize = 512
        fileLogHandler.maximumFileSize = 512
        handler.add(handler: fileLogHandler)
        log = Logger(label: label, handler)
        log.logLevel = .debug
        LoggingSystem.bootstrapInternal { _ in handler }
        try fileLogHandler.removeAllLogs()
    }

    func testFlush() throws {
        log.debug("test")
        try fileLogHandler.flush()
        
        try queue.sync {
            let baseURL = try! FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let logDirectory = baseURL.appendingPathComponent("hades-log", isDirectory: true)
            let logFileManager = LogFileManager(logDirectory: logDirectory)
            let logs = try logFileManager.queryLogFiles()
            XCTAssert(logs.count == 1, "count of logs is \(logs.count)")
        }
    }
    
    func testAutoFlush() throws {
        for i in 0..<40 {
            log.debug("test \(i)")
        }
        try fileLogHandler.flush()
        try queue.sync {
            let baseURL = try! FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let logDirectory = baseURL.appendingPathComponent("hades-log", isDirectory: true)
            let logFileManager = LogFileManager(logDirectory: logDirectory)
            let logs = try logFileManager.queryLogFiles()
            if let logFileURL = logs.first?.url {
                let content = try String(contentsOf: logFileURL)
                XCTAssert(content.hasSuffix("test 39"), "This file should end with 'test 39' according to the code at line 50.")
            }
            for log in logs {
                XCTAssert(log.size <= fileLogHandler.maximumFileSize)
            }
            if logs.count >= 2 {
                XCTAssert((logs[0].size + logs[1].size) > fileLogHandler.maximumFileSize)
            }
        }
    }
    
    func testZip() throws {
        for i in 0..<40 {
            log.debug("test \(i)")
        }
        try fileLogHandler.flush()
        
        try queue.sync {
            guard let url = try fileLogHandler.zipLogs() else {
                XCTAssert(false)
                return
            }
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attributes[.size] as? Int else {
                XCTAssert(false)
                return
            }
            XCTAssert(fileSize > 2_000 )
        }
    }
}
