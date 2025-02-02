//
//  localDirectory.swift
//  This file is part of the **localfix** project
//
//  Created by Cheuzh Asya
//

// MARK: - LocalizationDirectory

import Foundation

/// A structure representing a directory containing localization files.
///
/// This structure is responsible for managing localization files, extracting keys from them,
/// generating reports, and correcting missing keys across the files.
struct LocalizationDirectory {
    
    // MARK: - Properties
    
    /// A list of URLs pointing to the localization files in the directory.
    let localizationFiles: [URL]
    
    /// A set containing all unique localization keys found in the localization files.
    var allUniqueKeys: Set<String>
    
    /// A dictionary mapping each localization file's name to its set of localization keys.
    var localizationKeys: [String: Set<String>]
    
    /// Initializes a `LocalizationDirectory` with the provided localization files.
    ///
    /// This initializer sets up the `LocalizationDirectory` using a list of localization files. It processes
    /// these files to extract all unique localization keys and stores them in the instance. If an error occurs
    /// while extracting keys from the files, it throws an appropriate error.
    ///
    /// - Parameters:
    ///   - localizationFiles: An array of `URL` objects representing the paths to the localization files.
    ///
    /// - Throws:
    ///   - `LocalError` if an error occurs while extracting keys from the localization files. The specific
    ///     error thrown depends on the nature of the issue encountered during processing.
    init(localizationFiles: [URL]) throws {
        self.localizationFiles = localizationFiles
        let localKeys = try LocalizationDirectory.getLocalizationKeys(localFiles: localizationFiles)
        self.localizationKeys = localKeys
        self.allUniqueKeys = Set(localKeys.flatMap(\.value))
    }
    
    
    /// Extracts all unique keys from the localization files and stores them in `localizationKeys`.
    ///
    /// This method reads the contents of each localization file, parses it for localization keys,
    /// and updates both the `localizationKeys` dictionary and the `allUniqueKeys` set.
    ///
    /// - Throws: An error if the file content cannot be read or parsed.
    static func getLocalizationKeys(localFiles: [URL]) throws -> [String: Set<String>] {
        
        var tempLocalizationKeys: [String: Set<String>] = [:]
        for fileURL in localFiles {
            let fileContent = try readFileContent(fileURL)
            let setKey = parseFileContent(fileContent)
            
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            tempLocalizationKeys[fileName] = setKey
        }
        return tempLocalizationKeys
    }
    
    /// Generates a report of missing localization keys across files.
    ///
    /// - Parameter isForFile: A boolean indicating whether the report is written to a file or to the terminal.
    /// - Returns: A string representing the content of the report.
    /// - Throws: An error if the report cannot be generated.
    func writeReportData(isForFile: Bool) throws -> String {
        
        var reportText = String()
        
        if isForFile {
            reportText.append("\n## Final report")
            
            guard localizationKeys.values.first(where: { !allUniqueKeys.isSubset(of: $0) } ) != nil else {
                reportText.append("\n\nFile integrity check passed successfully!")
                return reportText
            }
            
            reportText.append("\n\n### Missing strings in localization files")
        } else {
            
            reportText.append(titleFormat("\n## Final report"))
            guard localizationKeys.values.first(where: { !allUniqueKeys.isSubset(of: $0) } ) != nil else {
                reportText.append(titleFormat("\n\nFile integrity check passed successfully!"))
                return reportText
            }
            reportText.append(titleFormat("\n\n### Missing strings in localization files"))
        }
        
        let sortedLocalizationKeys = localizationKeys.sorted(by: {$0.key < $1.key})
        
        for (fileName, fileKeys) in sortedLocalizationKeys {
            let missedKeys = allUniqueKeys.subtracting(fileKeys)
            guard !missedKeys.isEmpty else { continue }
            reportText.append(keysFormat(fileName: fileName, keys: missedKeys))
        }
        return reportText
    }
    
    /// Corrects missing localization keys in all files.
    ///
    /// This method inserts any missing keys into the localization files and ensures the keys are sorted alphabetically.
    ///
    /// - Throws: An error if the corrected files cannot be written to disk.
    func correctAllFiles() throws {
        
        var localizationKeysTemp = localizationKeys
        var fileKeysTranslation: [String: String]
        for fileURL in localizationFiles {
            
            fileKeysTranslation = Dictionary(uniqueKeysWithValues: allUniqueKeys.map { ($0, "") })
            let fileContent = try LocalizationDirectory.readFileContent(fileURL)
            fileKeysTranslation = getTranslationValues(in: fileKeysTranslation, by: fileContent)
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            localizationKeysTemp[fileName] = localizationKeysTemp[fileName]?.union(fileKeysTranslation.keys)
            
            let sortedKeysTranslation =  fileKeysTranslation.sorted { $0.key < $1.key }
            
            let correctLocalizationData = sortedKeysTranslation.reduce(into: "", {partialResult, sm in
                partialResult.append("\"\(sm.key)\" = \"\(sm.value)\";\n")
            })
            
            if let data = correctLocalizationData.data(using: .utf8) {
                try data.write(to: fileURL)
            }
        }
    }
    
    /// Reads the content of a localization file.
    ///
    /// - Parameter fileURL: The URL of the localization file to read.
    /// - Returns: The content of the file as a string.
    /// - Throws: `LocalError.FileReadingError` if the file cannot be read, or
    ///           `LocalError.FileDataConversionError` if the file's data cannot be converted to a string.
    static private func readFileContent(_ fileURL: URL) throws -> String {
        
        let fileName = fileURL.lastPathComponent
        do {
            let fileData = try Data(contentsOf: fileURL)
            if let fileContent = String(data: fileData, encoding: .utf8), !fileContent.isEmpty {
                return fileContent
            } else {
                throw LocalError.fileDataConversionError(fileName: fileName)
            }
        } catch {
            throw LocalError.fileReadingError(fileName: fileName)
        }
    }
    
    /// Parses the content of a localization file to extract its keys.
    ///
    /// - Parameter text: The content of the localization file as a string.
    /// - Returns: A set containing all the keys found in the file.
    static private func parseFileContent(_ text: String)  -> Set<String> {
        
        var localizationKey: Set<String> = Set()
        text.enumerateLines { line, _ in
            let modifiedText = line.components(separatedBy: "\"").dropFirst()
            if let key = modifiedText.first {
                localizationKey.insert(key)
            }
        }
        return localizationKey
    }
    
    /// Extracts translation values from the content of a localization file.
    ///
    /// - Parameters:
    ///   - dictionary: A dictionary that will be updated with translation key-value pairs.
    ///   - text: The content of the localization file.
    private func getTranslationValues(in dictionary: Dictionary<String, String>, by text: String) -> Dictionary<String, String> {
        
        var tempDictionary = dictionary
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let modifiedText = line.components(separatedBy: "=")
            guard modifiedText.count == 2 else { continue }
            
            let fileKeysTranslation = modifiedText.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\";"))
            }
            
            let key = fileKeysTranslation[0]
            let translation = fileKeysTranslation[1]
            tempDictionary[key] = translation
        }
        return tempDictionary
    }
}
