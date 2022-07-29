import XCTest
@testable import HadesLogger
@testable import Logging

final class HadesLoggerTests: XCTestCase {
    var log: Logger!
    
    override func setUp() async throws {
        let label = "xyz.123.qqq"
        let handler = HadesLogger.hadesHandler(label: label)
        log = Logger(label: label, handler)
        log.logLevel = .debug
        LoggingSystem.bootstrapInternal() { _ in handler }
    }
    
    func testExample() throws {
        // A simple test to see if the code will run.
        // You can cancel the following comments (line 22 and line 27 to see if the console log is printed,
        // and if the log file is generated properly.
        // The log file is inside the hades-log in the cache directory.
        // for example: `/Users/{NAME}/Library/Caches/hades-log/`
//        while true {
            sleep(1)
            log.debug("hugo", metadata: ["category": "hugo"])
            log.debug("mask", metadata: ["category": "mask"])
            log.debug("default")
//        }
    }
}
