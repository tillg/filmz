//
//  OSLogHandler.swift
//  YouShouldBeLogging
//
//  Created by Jacob Bartlett on 14/02/2025.
//

import Foundation
import OSLog
import Logging

struct OSLogHandler: LogHandler {
    let label: String
    var metadata: Logging.Logger.Metadata = [:]
    var logLevel: Logging.Logger.Level = .trace
    private let logger = os.Logger(subsystem: "com.grtnr.Filmz", category: "Logging")
    
    subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
    
    func log(level: Logging.Logger.Level, message: Logging.Logger.Message, metadata: Logging.Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        switch level {
        case .trace:
            logger.trace("\(message, privacy: .public)")
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .notice:
            logger.notice("\(message, privacy: .public)")
        case .warning:
            logger.warning("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .critical:
            logger.critical("\(message, privacy: .public)")
        }
    }
}
