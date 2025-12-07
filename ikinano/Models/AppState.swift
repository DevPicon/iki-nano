//
//  AppState.swift
//  ikinano
//
//  Created by Armando Picon on 05-12-25.
//

import Foundation

/// Represents the different states of the application
enum AppState: Equatable {
    /// Initial state - no model downloaded
    case idle

    /// Model is being downloaded with progress (0.0 to 1.0)
    case downloading(progress: Double)

    /// Model is being loaded into memory
    case initializing

    /// Model is being deleted
    case deleting

    /// Model is ready to use
    case ready

    /// Processing inference request
    case processing

    /// Error occurred with description
    case error(String)
}
