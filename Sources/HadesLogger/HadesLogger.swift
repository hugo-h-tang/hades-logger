import Logging
import Foundation

public struct HadesLogger {
    public static func hadesHandler(label: String) -> Logging.LogHandler {
        let queue = DispatchQueue.init(label: label)
        var proxyHandler = ProxyLogHandler(loggerQueue: queue, logLevel: .debug, metadata: [:])
        let oslogHandler = OSLogHandler(label: label)
        let fileLogHandler = FileLogHandler()
        proxyHandler.add(handler: oslogHandler)
        proxyHandler.add(handler: fileLogHandler)
        return proxyHandler
    }
}
