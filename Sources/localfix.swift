import ArgumentParser
import Foundation

// MARK: - Localfix

/// A command-line tool to check the integrity of localization files.
///
/// This tool helps ensure that localization files are synchronized across languages, and it can
/// also correct missing keys or lines by inserting them where necessary.
///
/// The `locafix` tool can generate a report of missing lines across files. It processes
/// localization files named in the format `localization-lang` where `lang` is a two-letter language code (e.g. `localization-en`, `localization-fr`).
///
/// **Example usage:**
/// - `locafix --files /path/to/localization --report /path/to/report --correct`
@main
struct Localfix: ParsableCommand {
    
    // MARK: - Properties
    
    /// The directory where localization files are located.
    ///
    /// If this option is not specified, the current working directory will be used.
    ///
    /// **Example:** `/Users/incetro/Desktop/localisation`
    @Option(name: .customLong("files"), help: "The directory containing localization files.")
    var filesPath: String?
    
    /// The directory where the report file `localization_report.md` will be generated.
    ///
    /// If this option is not specified, the report will be generated to the terminal.
    ///
    /// **Example:** `/Users/incetro/Desktop` or `.` to generate report to the terminal.
    @Option(name: .customLong("report"), help: "The directory where the report will be generated.")
    var reportPath: String?
    
    /// A flag indicating whether to correct missing keys in the localization files.
    ///
    /// If this flag is provided, the tool will insert any missing keys/lines into the localization files
    /// and ensure that the keys are sorted to match line numbers across all languages.
    @Flag(name: .customLong("correct"), help: "Enable correction of localization files.")
    var isNeedToCorrect = false
    
    /// Executes the main logic of the command.
    func run() throws {
        do {
            let localApp = try LocalApp(filesURL: filesPath, reportPath: reportPath ?? "", fileManager: .default)
            let localDirectory = try localApp.getLocalizationDirectory()
            
            if let report = reportPath, !report.isEmpty {
                try localApp.generateReport(localDirectory: localDirectory)
            }
            
            if isNeedToCorrect {
                try localApp.correctLocal(localDirectory: localDirectory)
            }
        } catch let error as LocalError {
            print(error.errorDescription)
        }
        
    }
}

