//
//  localError.swift
//  This file is part of the **localfix** project
//
//  Created by Cheuzh Asya
//

/// Enum representing various errors that can occur during localization file processing.
import Foundation

enum LocalError: LocalizedError {
    
    /// Error indicating a failure to convert file data into a string.
    case FileDataConversionError(fileName: String)
    
    /// Error indicating a failure to read a file.
    case FileReadingError(fileName: String)
    
    /// Error indicating that no localization files were found in the specified directory.
    case NotParsingFiles(directoryURL: String)
    
    /// Error indicating that the provided report URL is invalid.
    case InvalidReportURL(reportURL: String)
    
    /// Error indicating a failure to write the report file.
    case FileWritingError
    
    /// Provides a localized description for each error case.
    var errorDescription: String {
        
        switch self {
        case .FileDataConversionError(let fileName):
            return "Failed to convert data from file \(fileName) to a string."
            
        case .FileReadingError(let fileName):
            return "Failed to read the file \(fileName)."

        case .NotParsingFiles(let directoryURL):
            return "No localization files were found in the directory \(directoryURL)."
            
        case .InvalidReportURL(let reportURL):
            return "The report directory path is invalid: \(reportURL)."
            
        case .FileWritingError:
            return "Failed to write the report to a file."
        }
    }
}
