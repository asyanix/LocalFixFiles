import ArgumentParser
import Foundation

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
    /// The directory where localization files are located.
    ///
    /// If this option is not specified, the current working directory will be used.
    ///
    /// **Example:** `/Users/incetro/Desktop/localisation`
    @Option(help: "The directory containing localization files.")
    var files: String?
    
    /// The directory where the report file `localization_report.md` will be generated.
    ///
    /// If this option is not specified, the report will be generated to the terminal.
    ///
    /// **Example:** `/Users/incetro/Desktop` or `.` to generate report to the terminal.
    @Option(help: "The directory where the report will be generated.")
    var report: String?
    
    /// A flag indicating whether to correct missing keys in the localization files.
    ///
    /// If this flag is provided, the tool will insert any missing keys/lines into the localization files
    /// and ensure that the keys are sorted to match line numbers across all languages.
    @Flag(help: "Enable correction of localization files.")
    var correct: Bool = false
    
    /// Executes the main logic of the command.
    func run() throws {
        do {
            var localApp = try localApp(filesURL: files, reportPath: report ?? "")
            
            if let report = report, !report.isEmpty {
                try localApp.generateReport()
            }
            
            if correct
            {
                try localApp.correctLocal()
            }
        }
        /// Catches and prints any `LocalError` that occurs.
        catch let error as LocalError {
            print(error.errorDescription)
        }
        
    }
}

