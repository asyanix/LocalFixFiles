//
//  File.swift
//
//
//  Created by Асиет Чеуж on 06.08.2024.
//

import Foundation

struct LocalizationDirectory
{
    let fileManager = FileManager.default
    lazy var currentDirectoryURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    
    var allUniqueKeys: Set<String> = Set()
    var localizationKeys: Dictionary<String, Set<String>> = [:]
    
    mutating func getAllKeys() throws
    {
        do {
            let allFiles = try fileManager.contentsOfDirectory(
                at: currentDirectoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            
            let localizationFiles = allFiles.filter { $0.lastPathComponent.contains("localization-") }
            
            guard !localizationFiles.isEmpty else
            {
                throw LocalError.NotParsingFiles
            }
            
            for fileURL in localizationFiles {
                do {
                    let fileContent = try readFileContent(fileURL)
                    let fileName = fileURL.lastPathComponent
                    let setKey = parseFileContent(fileContent)
                    
                    localizationKeys[fileName] = setKey
                    allUniqueKeys = allUniqueKeys.union(setKey)
                }
            }
        } catch {
            throw LocalError.NotParsingFiles
        }
    }
    
    func readFileContent(_ fileURL: URL) throws -> String
    {
        let fileName = fileURL.lastPathComponent
        do {
            let fileData = try Data(contentsOf: fileURL)
            if let fileContent = String(data: fileData, encoding: .utf8) {
                return fileContent
            } else {
                throw LocalError.FileDataConversionError(fileName: fileName)
            }
        } catch {
            throw LocalError.FileReadingError(fileName: fileName)
        }
    }
    
    func parseFileContent(_ text: String)  -> Set<String>
    {
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
    
    func generateReport() throws -> String
    {
        guard !allUniqueKeys.isEmpty && !localizationKeys.isEmpty else
        {
            throw LocalError.NotFoundKeys
        }
        
        var reportText = String()
        
        reportText.append(titleFormat("\n## Итоговый отчёт"))
        reportText.append(titleFormat("\n\n### Недостающие строки в файлах локализации"))
        
        guard localizationKeys.values.allSatisfy({ !allUniqueKeys.subtracting($0).isEmpty }) else
        {
            return titleFormat("Проверка на целостность файлов прошла успешно!")
        }
        
        for (fileName, fileKeys) in localizationKeys
        {
            let missedKeys = allUniqueKeys.subtracting(fileKeys)
            reportText.append(keysFormat(fileName: fileName, keys: missedKeys))
        }
        
        return reportText
    }
}
