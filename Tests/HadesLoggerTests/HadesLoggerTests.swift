import XCTest
@testable import HadesLogger
@testable import Logging

final class HadesLoggerTests: XCTestCase {
    var log: Logger!
    
    override func setUp() async throws {
        let label = "xyz.123.qqq"
        var handler = ProxyLogHandler(loggerQueue: DispatchQueue.init(label: label), logLevel: .debug, metadata: [:])
        let oslogHandler = OSLogHandler(label: label)
        handler.add(handler: oslogHandler)
        log = Logger(label: label, handler)
        log.logLevel = .debug
        LoggingSystem.bootstrap { _ in handler }
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        log.debug("hugo", metadata: ["category": "hugo"])
        log.debug("mask", metadata: ["category": "mask"])
        log.debug("default")
        XCTAssertEqual(HadesLogger().text, "Hello, World!")
    }
}
