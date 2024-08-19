//
//  localError.swift
//  This file is part of the **localfix** project
//
//  Created by Cheuzh Asya
//

/// Enum representing various errors that can occur during localization file processing.
import Foundation

// MARK: - LocalError

enum LocalError: LocalizedError {
    
    // MARK: - Cases
    
    /// Error indicating a failure to convert file data into a string.
    case fileDataConversionError(fileName: String)
    
    /// Error indicating a failure to read a file.
    case fileReadingError(fileName: String)
    
    /// Error indicating that no localization files were found in the specified directory.
    case notParsingFiles(directoryURL: String)
    
    /// Error indicating that the provided report URL is invalid.
    case invalidReportURL(reportURL: String)
    
    // MARK: - Properties
    
    /// Provides a localized description for each error case.
    var errorDescription: String {
        switch self {
        case .fileDataConversionError(let fileName):
            return "Failed to convert data from file \(fileName) to a string."
        case .fileReadingError(let fileName):
            return "Failed to read the file \(fileName)."
        case .notParsingFiles(let directoryURL):
            return "No localization files were found in the directory \(directoryURL)."
        case .invalidReportURL(let reportURL):
            return "The report directory path is invalid: \(reportURL)."
        }
    }
}
