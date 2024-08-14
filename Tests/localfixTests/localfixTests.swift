//
//  localfixTests.swift
//  This file is part of the **localfix** project
//
//  Created by Cheuzh Asya
//

import XCTest
@testable import localfix

/// Unit tests for the `localfix` command-line tool.
final class localfixTests: XCTestCase {
    
    /// URL for a temporary directory where test localization files will be created.
    var tempDirectoryURL: URL!
    
    /// Create a temporary directory for the tests/
    /// This directory is created before each test to hold test localization files.
    override func setUpWithError() throws {
        let tempDirectory = NSTemporaryDirectory()
        let tempDirectoryURL = URL(fileURLWithPath: tempDirectory).appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        self.tempDirectoryURL = tempDirectoryURL
    }
    
    /// Cleans up the temporary directory after each test.
    /// The directory is deleted after the test completes.
    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: tempDirectoryURL)
    }
    
    /// Creates a localization file in the temporary directory with the given content.
    func createLocalizationFile(fileName: String, content: String) throws -> URL {
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    /// Parses the content of a report and extracts missing keys from the localization files.
    func parseReportContent(_ reportContent: String) -> Dictionary<String, Set<String>>
    {
        let modifiedContent = reportContent.replacingOccurrences(of: "\n", with: "").components(separatedBy: "**").dropFirst()
        var resultData: [String: Set<String>] = [:]
        var currentKey: String?
        
        for item in modifiedContent {
            if item.hasPrefix("localization-") {
                currentKey = item
                resultData[currentKey!] = Set<String>()
            } else if let key = currentKey {
                let values = item.replacingOccurrences(of: "-", with: "").split(separator: "`").compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                for value in values {
                    if !value.isEmpty {
                        resultData[key]?.insert(value)
                    }
                }
            }
        }
        
        return resultData
    }
    
    /// Tests the report generation for localization files with missing keys.
    /// The test verifies that missing keys are correctly identified for different files.
    func testGenerateReportAllFilesWrong() throws {
        let testData: Dictionary<String, Set<String>> = [
            "localization-es": Set(["settings", "login"]),
            "localization-ru": Set(["logout"])
        ]
        
        let ruLocalization = """
        "welcome_message" = "Добро пожаловать!";
        "login" = "Войти";
        "settings" = "Настройки";
        """
        
        let esLocalization = """
        "welcome_message" = "¡Bienvenido!";
        "logout" = "Cerrar sesión";
        """
        
        _ = try createLocalizationFile(fileName: "localization-ru.txt", content: ruLocalization)
        _ = try createLocalizationFile(fileName: "localization-es.txt", content: esLocalization)
        
        let app = try localApp(filesURL: tempDirectoryURL.path, reportPath: "")
        let reportContent = try app.localDirectory.writeReportData(isForFile: true)
        
        let resultData = parseReportContent(reportContent)
        
        XCTAssertEqual(resultData, testData)
    }
    
    /// Tests report generation with one correct localization file.
    /// This test checks if missing keys are properly reported for files with incomplete content.
    func testGenerateReportWithOneCorrectFile() throws {
        let testData: Dictionary<String, Set<String>> = [
            "localization-fr": Set(["welcome_message", "settings"]),
            "localization-it": Set(["logout","login"])
        ]
        
        let enLocalization = """
        "welcome_message" = "Welcome!"
        "logout" = "Logout"
        "login" = "Login"
        "settings" = "Settings"
        """
        
        let frLocalization = """
        "login" = "Connexion"
        "logout" = "Déconnexion"
        """
        
        let itLocalization = """
        "welcome_message" = "Benvenuto!"
        "settings" = "Impostazioni"
        """
        
        _ = try createLocalizationFile(fileName: "localization-en.txt", content: enLocalization)
        _ = try createLocalizationFile(fileName: "localization-fr.txt", content: frLocalization)
        _ = try createLocalizationFile(fileName: "localization-it.txt", content: itLocalization)
        
        let app = try localApp(filesURL: tempDirectoryURL.path, reportPath: "")
        let reportContent = try app.localDirectory.writeReportData(isForFile: true)
        
        let resultData = parseReportContent(reportContent)
        
        XCTAssertEqual(resultData, testData)
    }
    
    /// Tests report generation when all localization files are correct.
    /// The test verifies that the report indicates no missing keys.
    func testGenerateReportAllFilesCorrect() throws {
        let testData = """
        \n## Итоговый отчёт
        
        Проверка на целостность файлов прошла успешно!
        """
        
        let enLocalization = """
        "welcome_message" = "Welcome!"
        "logout" = "Logout"
        "login" = "Login"
        """
        
        let ruLocalization = """
        "welcome_message" = "Добро пожаловать!"
        "logout" = "Выйти"
        "login" = "Войти"
        """
        
        let esLocalization = """
        "welcome_message" = "¡Bienvenido!"
        "logout" = "Cerrar sesión"
        "login" = "Iniciar sesión"
        """
        
        _ = try createLocalizationFile(fileName: "localization-en.txt", content: enLocalization)
        _ = try createLocalizationFile(fileName: "localization-ru.txt", content: ruLocalization)
        _ = try createLocalizationFile(fileName: "localization-es.txt", content: esLocalization)
        
        let app = try localApp(filesURL: tempDirectoryURL.path, reportPath: "")
        let reportContent = try app.localDirectory.writeReportData(isForFile: true)
        
        XCTAssertEqual(reportContent, testData)
    }
    
    /// Tests the correction of localization files.
    /// This test ensures that missing keys are added to files and their content is corrected.
    func testCorrectFiles() throws {
        let esLocalization = """
        "welcome_message" = "¡Bienvenido!"
        "logout" = "Cerrar sesión"
        "login" = "Iniciar sesión"
        """
        
        let frLocalization = """
        "login" = "Connexion"
        "logout" = "Déconnexion"
        """
        
        let itLocalization = """
        "welcome_message" = "Benvenuto!"
        "settings" = "Impostazioni"
        """
        
        _ = try createLocalizationFile(fileName: "localization-es.txt", content: esLocalization)
        _ = try createLocalizationFile(fileName: "localization-fr.txt", content: frLocalization)
        _ = try createLocalizationFile(fileName: "localization-it.txt", content: itLocalization)
        
        var app = try localApp(filesURL: tempDirectoryURL.path, reportPath: "")
        try app.correctLocal()
        
        XCTAssertTrue( app.localDirectory.localizationKeys.allSatisfy({$0.value.isSubset(of: app.localDirectory.allUniqueKeys)}) )
    }
    
    /// Tests that an error is thrown when an invalid report URL is provided.
    func testErrorInvalidReportURL() throws {
        let wrongURL = tempDirectoryURL.appendingPathComponent("example.txt").absoluteString
        /// when
        XCTAssertThrowsError(try localApp(filesURL: wrongURL, reportPath: ""))
        { error in
            /// then
            if let error = error as? LocalError {
                XCTAssertEqual(error.errorDescription,  LocalError.InvalidReportURL(reportURL: wrongURL).errorDescription)
            }
        }
    }
    
    /// Tests that an error is thrown when no localization files are found in the directory.
    func testErrorNotParsingFiles() throws {
        _ = try createLocalizationFile(fileName: "example-1.txt", content: "")
        _ = try createLocalizationFile(fileName: "example-2.txt", content: "")
        _ = try createLocalizationFile(fileName: "example-3.txt", content: "")
        
        /// when
        XCTAssertThrowsError(try localApp(filesURL: tempDirectoryURL.absoluteString, reportPath: ""))
        { error in
            /// then
            if let error = error as? LocalError {
                XCTAssertEqual(error.errorDescription,  LocalError.NotParsingFiles(directoryURL: tempDirectoryURL.absoluteString).errorDescription)
            }
        }
    }
}
