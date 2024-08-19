//
//  localApp.swift
//  This file is part of the **localfix** project
//
//  Created by Cheuzh Asya
//

import Foundation

// MARK: - LocalApp

/// A structure representing the main application logic for handling localization files.
///
/// This structure initializes the localization file directory, generates reports for missing localization keys,
/// and corrects localization files by adding missing keys and ensuring consistency across all files.
struct LocalApp {
    
    // MARK: - Properties
    
    /// The URL where the report will be generated, or `nil` if report will be generated in the terminal.
    private let reportURL: URL?
    
    /// The URL of the current directory where localization files are located.
    private let currentDirectoryURL: URL
    
    /// A file manager instance used for file system operations.
    private let fileManager: FileManager
    
    /// Initializes the `localApp` instance.
    ///
    /// This initializer sets up the localization files directory and validates the report path.
    /// It filters out any files in the directory that do not follow the `localization-*` naming convention.
    ///
    /// - Parameters:
    ///   - filesURL: The path to the directory containing localization files. If `nil`, the current directory is used.
    ///   - reportPath: The path where the report file will be generated. If `"."` or an empty string, report will be generated to the terminal.
    ///   - fileManager: A file manager instance used for file system operations.
    init(filesURL: String?, reportPath: String, fileManager: FileManager) throws {
        self.fileManager = fileManager
        self.reportURL = reportPath == "." || reportPath.isEmpty ? nil : URL(fileURLWithPath: reportPath)
        self.currentDirectoryURL = URL(fileURLWithPath: filesURL ?? fileManager.currentDirectoryPath)
    }
    
    /// Retrieves the localization directory by filtering files that contain localization data.
    ///
    /// This function scans the specified directory for files that match the naming pattern
    /// for localization files (`localization-*`). It filters out hidden files and subdirectories,
    /// returning only the localization files. If no localization files are found, it throws an error.
    ///
    /// - Throws:
    ///   - `LocalError.notParsingFiles` if no localization files are found in the specified directory.
    func getLocalizationDirectory() throws -> LocalizationDirectory {
        let allFiles = try fileManager.contentsOfDirectory(
            at: currentDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        
        let localizationFiles = allFiles.filter { $0.lastPathComponent.contains("localization-") }
        
        guard !localizationFiles.isEmpty else {
            throw LocalError.notParsingFiles(directoryURL: currentDirectoryURL.absoluteString)
        }
        return try LocalizationDirectory(localizationFiles: localizationFiles)
    }
    
    /// Generates a report of missing localization keys.
    ///
    /// This method either prints the report to the console or writes it to a file in the specified report directory.
    /// If the report URL is `nil`, the report is printed to the console. Otherwise, it writes to `loclalization_report.md`.
    ///
    /// - Throws: An error if writing the report file fails.
    /// - Throws: An error if the report path is invalid or if there are no localization files in the directory.
    func generateReport(localDirectory: LocalizationDirectory) throws {
        if let reportFileURL = reportURL {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: reportFileURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                throw LocalError.invalidReportURL(reportURL: reportFileURL.absoluteString)
            }
        }
        
        if let reportURL = reportURL {
            let reportData = try localDirectory.writeReportData(isForFile: true)
            
            let fileReportURL = reportURL.appendingPathComponent("localization_report.md")
            
            if let data = reportData.data(using: .utf8) {
                try data.write(to: fileReportURL)
                print(titleFormat("\nReport successfully wrote to file!\n"))
            }
        }
        else {
            let reportData = try localDirectory.writeReportData(isForFile: false)
            print(reportData)
            return
        }
    }
    
    
    /// Corrects localization files by adding any missing keys and ensuring key consistency.
    ///
    /// This method scans all localization files and inserts any missing localization keys across all files,
    /// ensuring that the localization keys are consistent and sorted in each file.
    ///
    /// - Throws: An error if any file fails to be corrected.
    func correctLocal(localDirectory: LocalizationDirectory) throws {
        try localDirectory.correctAllFiles()
        print(titleFormat("\nLocalization files successfully corrected!\n"))
    }
}

/// Formats the provided text as a title with a specific color and style.
///
/// - Parameter text: The text to be formatted.
/// - Returns: A string representing the formatted title.
func titleFormat(_ text: String) -> String {
    let color = "\u{001B}[93m"
    let style = "\u{001B}[1m"
    return "\(style)\(color)\(text)\u{001B}[0m"
}

/// Formats the missing localization keys for a given file.
///
/// - Parameters:
///   - fileName: The name of the localization file.
///   - keys: A set of missing keys in the file.
/// - Returns: A string representing the formatted list of missing keys.
func keysFormat(fileName: String, keys: Set<String>) -> String {
    var keysText = String()
    
    keysText.append("\n\n- **\(fileName)**")
    keys.forEach { key in
        keysText.append("\n  -`\(key)`")
    }
    return keysText
}
