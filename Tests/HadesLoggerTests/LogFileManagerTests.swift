//
//  LogFileManagerTests.swift
//  
//
//  Created by Hugo L on 2022/7/28.
//

import XCTest

@testable import HadesLogger
class LogFileManagerTests: XCTestCase {
    var logFileManager: LogFileManager!
    var logDirectory: URL!

    override func setUpWithError() throws {
        let baseURL = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        logDirectory = baseURL.appendingPathComponent("hades-log", isDirectory: true)
        logFileManager = LogFileManager(logDirectory: logDirectory)
        try logFileManager.removeAllLogs()
    }

    func testCreateLogFile() throws {
        try logFileManager.createEmptyDirectoryIfNeeded(at: logDirectory)
        let file1URL = logDirectory.appendingPathComponent("1.txt", isDirectory: false)
        let result = logFileManager.createLogFile(at: file1URL)
        XCTAssert(result)
    }
    
    func testAppend() throws {
        let file1URL = logDirectory.appendingPathComponent("1.txt", isDirectory: false)
        try logFileManager.append("123".data(using: .utf8), at: file1URL)
        try logFileManager.append("abc".data(using: .utf8), at: file1URL)
        let content = try String(contentsOf: file1URL)
        XCTAssert(content == "123abc")
    }
    
    func testQueryLogFiles() throws {
        let file1URL = logDirectory.appendingPathComponent("1.txt", isDirectory: false)
        logFileManager.createLogFile(at: file1URL)
        sleep(1)
        let file2URL = logDirectory.appendingPathComponent("2.txt", isDirectory: false)
        logFileManager.createLogFile(at: file2URL)
        let logFiles = try logFileManager.queryLogFiles()
        let lastPathComponents = logFiles.map { $0.url.lastPathComponent }
        XCTAssert(lastPathComponents == ["2.txt", "1.txt"])
    }
}
