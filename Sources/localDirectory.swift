//
//  localDirectory.swift
//  This file is part of the **localfix** project
//
//  Created by Cheuzh Asya
//

import Foundation

/// A structure representing a directory containing localization files.
///
/// This structure is responsible for managing localization files, extracting keys from them,
/// generating reports, and correcting missing keys across the files.
struct LocalizationDirectory
{
    /// A list of URLs pointing to the localization files in the directory.
    internal let localizationFiles: [URL]
    
    /// A set containing all unique localization keys found in the localization files.
    internal var allUniqueKeys: Set<String> = Set()
    
    /// A dictionary mapping each localization file's name to its set of localization keys.
    internal var localizationKeys: Dictionary<String, Set<String>> = [:]
    
    
    /// Extracts all unique keys from the localization files and stores them in `localizationKeys`.
    ///
    /// This method reads the contents of each localization file, parses it for localization keys,
    /// and updates both the `localizationKeys` dictionary and the `allUniqueKeys` set.
    ///
    /// - Throws: An error if the file content cannot be read or parsed.
    mutating func getAllKeys() throws {
        
        for fileURL in localizationFiles {
            do {
                let fileContent = try readFileContent(fileURL)
                let setKey = parseFileContent(fileContent)
                
                let fileName = fileURL.deletingPathExtension().lastPathComponent
                localizationKeys[fileName] = setKey
                allUniqueKeys = allUniqueKeys.union(setKey)
            }
        }
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
            
            guard localizationKeys.values.first(where:{  !allUniqueKeys.isSubset(of: $0) } ) != nil else
            {
                reportText.append("\n\nFile integrity check passed successfully!")
                return reportText
            }
            
            reportText.append("\n\n### Missing strings in localization files")
        }
        else {
            reportText.append(titleFormat("\n## Final report"))
            
            guard localizationKeys.values.first(where:{  !allUniqueKeys.isSubset(of: $0) } ) != nil else
            {
                reportText.append(titleFormat("\n\nFile integrity check passed successfully!"))
                return reportText
            }
            
            reportText.append(titleFormat("\n\n### Missing strings in localization files"))
        }
        
        let sortedLocalizationKeys = localizationKeys.sorted(by: {$0.key < $1.key})
        
        for (fileName, fileKeys) in sortedLocalizationKeys
        {
            let missedKeys = allUniqueKeys.subtracting(fileKeys)
            guard !missedKeys.isEmpty else
            {
                continue
            }
            reportText.append(keysFormat(fileName: fileName, keys: missedKeys))
        }
        
        return reportText
    }
    
    /// Corrects missing localization keys in all files.
    ///
    /// This method inserts any missing keys into the localization files and ensures the keys are sorted alphabetically.
    ///
    /// - Throws: An error if the corrected files cannot be written to disk.
    mutating func correctAllFiles() throws {
        var fileKeysTranslation: Dictionary<String, String>
        
        for fileURL in localizationFiles {
            fileKeysTranslation = Dictionary(uniqueKeysWithValues: allUniqueKeys.map { ($0, "") })
            
            do {
                let fileContent = try readFileContent(fileURL)
                getTranslationValues(in: &fileKeysTranslation, by: fileContent)
                let fileName = fileURL.deletingPathExtension().lastPathComponent
                localizationKeys[fileName] = localizationKeys[fileName]?.union(fileKeysTranslation.keys)
                
                let sortedKeysTranslation =  fileKeysTranslation.sorted { $0.key < $1.key }
                
                let correctLocalizationData = generateNewLocalization(by: sortedKeysTranslation)
                
                if let data = correctLocalizationData.data(using: .utf8) {
                    do {
                        try data.write(to: fileURL)
                    } catch {
                        throw LocalError.FileWritingError
                    }
                }
            }
        }
    }
    
    /// Reads the content of a localization file.
    ///
    /// - Parameter fileURL: The URL of the localization file to read.
    /// - Returns: The content of the file as a string.
    /// - Throws: `LocalError.FileReadingError` if the file cannot be read, or
    ///           `LocalError.FileDataConversionError` if the file's data cannot be converted to a string.
    private func readFileContent(_ fileURL: URL) throws -> String {
        let fileName = fileURL.lastPathComponent
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            if let fileContent = String(data: fileData, encoding: .utf8), !fileContent.isEmpty {
                return fileContent
            } else {
                throw LocalError.FileDataConversionError(fileName: fileName)
            }
        } catch {
            throw LocalError.FileReadingError(fileName: fileName)
        }
    }
    
    /// Parses the content of a localization file to extract its keys.
    ///
    /// - Parameter text: The content of the localization file as a string.
    /// - Returns: A set containing all the keys found in the file.
    private func parseFileContent(_ text: String)  -> Set<String> {
        var localizationKey: Set<String> = Set()
        
        text.enumerateLines { line, _ in
            let modifiedText = line.components(separatedBy: "\"").dropFirst()
            if let key = modifiedText.first
            {
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
    private mutating func getTranslationValues(in dictionary: inout Dictionary<String, String>, by text: String) {
        
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
            dictionary[key] = translation
        }
    }
    
    /// Generates a new localization file content from a dictionary of key-value pairs.
    ///
    /// - Parameter dictionary: A sorted dictionary of localization keys and their translations.
    /// - Returns: A string representing the new content of the localization file.
    private func generateNewLocalization(by dictionary: [Dictionary<String, String>.Element]) -> String
    {
        var newLocalization = String()
        for (key, value) in dictionary
        {
            newLocalization.append("\"\(key)\" = \"\(value)\";\n")
        }
        return newLocalization
    }
    
}
