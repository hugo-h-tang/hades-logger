//
//  FileLogHandler.swift
//  
//
//  Created by Hugo L on 2022/7/27.
//

import Foundation
import Logging
import ZIPFoundation

class FileLogHandler: LogHandler {
    enum Error: Swift.Error {
        // maximumNumberOfLogFiles should bigger then 0
        case wrongMaximumNumberOfLogFiles
    }
    
    var loggerQueue: DispatchQueue?
    var logLevel: Logger.Level = .warning
    var metadata: Logger.Metadata = [:]
    
    var fileDateFormatter: DateFormatter
    var maximumNumberOfLogFiles: Int = 5
    var maximumFileSize: Int = 5_120_000
    var bufferSize: Int = 512
    var currentLogFile: LogFile?
    private var logFileManager: LogFileManager
    private var buffer: Data?
    
    init() {
        fileDateFormatter = DateFormatter()
        fileDateFormatter.dateFormat = "yyyy-MM-dd"
        
        let baseURL = try! FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let logDirectory = baseURL.appendingPathComponent("hades-log", isDirectory: true)
        logFileManager = LogFileManager(logDirectory: logDirectory)
    }
    
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }
    
    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        if self.buffer == nil {
            self.buffer = Data()
        }
        guard let data = "\n\(message)".data(using: .utf8) else {
            return
        }
        if let buffer = buffer, (buffer.count + data.count >= bufferSize) {
            try? _flush(true)
        }
        self.buffer?.append(data)
        try? self.flushIfNeeded()
    }
    
    @discardableResult
    func touchNewLogFile() throws -> LogFile? {
        let logFileURL = try generateNameForLogFile()
        _ = logFileManager.createLogFile(at: logFileURL)
        try cleanup()
        let logFiles = try logFileManager.queryLogFiles()
        currentLogFile = logFiles.first
        return currentLogFile
    }
    
    func generateNameForLogFile() throws -> URL {
        let logFiles = try logFileManager.queryLogFiles()
        guard let indexWithExtention = logFiles.first?.url.lastPathComponent.split(separator: "-").last,
              let indexStr = indexWithExtention.split(separator: ".").first,
              let index = Int(indexStr) else {
            let name = "\(fileDateFormatter.string(from: Date()))-\(1).log"
            return logFileManager.logDirectory.appendingPathComponent(name)
        }
        let name = "\(fileDateFormatter.string(from: Date()))-\(index + 1).log"
        return logFileManager.logDirectory.appendingPathComponent(name)
    }
    
    // 将缓存写入文件
    private func _flush(_ touchNewFile: Bool = true) throws {
        guard var buffer = buffer else {
            return
        }
        if currentLogFile == nil {
            try touchNewLogFile()
        }
        guard let currentLogFile = currentLogFile else {
            return
        }
        
        while true {
            let fileURL = currentLogFile.url
            let writtenData = buffer.prefix(bufferSize)
            buffer = buffer.subdata(in: writtenData.count..<buffer.count)
            try logFileManager.append(writtenData, at: fileURL)
            self.currentLogFile?.size += writtenData.count
            if touchNewFile {
                try touchNewLogFile()
            }
            
            if buffer.count < bufferSize {
                break
            }
        }
        self.buffer = buffer
    }
    
    func flush() throws {
        loggerQueue?.async {
            try? self._flush(false)
        }
    }
    
    private func flushIfNeeded() throws {
        guard (buffer?.count ?? 0) >= bufferSize else {
            return
        }
        try _flush(true)
    }
    
    /// 清理日志文件
    func cleanup() throws {
        let logFiles = try logFileManager.queryLogFiles()
        guard logFiles.count > maximumNumberOfLogFiles else {
            return
        }
        guard (logFiles.count - maximumNumberOfLogFiles) > 0 else {
            throw Error.wrongMaximumNumberOfLogFiles
        }
        let removeLogs = logFiles.suffix(logFiles.count - maximumNumberOfLogFiles)
        for file in removeLogs {
            try logFileManager.remove(at: file.url)
        }
    }
    
    func removeAllLogs() throws {
        try logFileManager.removeAllLogs()
    }
    
    /// 将日志文件打包
    /// - Returns: zip文件的URL
    func zipLogs() throws -> URL? {
        let archiveURL = logFileManager.logDirectory.appendingPathComponent("logs.zip")
        guard let archive = Archive(url: archiveURL, accessMode: .create) else  {
            return nil
        }
        let logFiles = try logFileManager.queryLogFiles()
        for file in logFiles.filter({ $0.url.lastPathComponent.hasSuffix(".log") }) {
            try archive.addEntry(
                with: file.url.lastPathComponent,
                relativeTo: file.url.deletingLastPathComponent()
            )
        }
        try archive.data?.write(to: archiveURL)
        return archiveURL
    }
}
