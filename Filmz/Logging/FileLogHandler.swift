//
//  FileLogHandlers.swift
//  YouShouldBeLogging
//
//  Created by Jacob Bartlett on 14/02/2025.
//

import Foundation
import Logging

struct FileLogHandler: LogHandler {
    let label: String
    var metadata: Logger.Metadata = [:]
    var logLevel: Logger.Level = .info
    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("app_errors.log")
    
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
    
    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        let logEntry = "[\(level)] \(message)\n"
        try? logEntry.append(to: fileURL)
    }
}

extension String {
    func append(to fileURL: URL) throws {
        let data = self.data(using: .utf8)!
        if FileManager.default.fileExists(atPath: fileURL.path) {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } else {
            try data.write(to: fileURL, options: .atomic)
        }
    }
}
