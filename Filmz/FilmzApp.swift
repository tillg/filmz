//
//  FilmzApp.swift
//  Filmz
//
//  Created by Till Gartner on 16.01.25.
//

import SwiftUI
import Logging

@main
struct FilmzApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupLogging() {
        LoggingSystem.bootstrap { label in
            MultiplexLogHandler([
                OSLogHandler(label: label),
                FileLogHandler(label: label),
            ])
        }
    }
}
