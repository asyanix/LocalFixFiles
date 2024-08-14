# LocalFixFiles

A command-line tool to check the integrity of localization files. 
This tool helps ensure that localization files are synchronized across languages, and it can also correct missing keys or lines by inserting them where necessary.

The `locafix` tool can generate a report `localization_report.md` of missing lines across files. It processes localization files named in the format `localization-lang` where `lang` is a two-letter language code (e.g. `localization-en`, `localization-fr`).

**Parameters:**
  --files <files>         The directory containing localization files.
  --report <report>       The directory where the report will be generated.
  --correct               Enable correction of localization files.

**Usage:**
`localfix [--files <files>] [--report <report>] [--correct]`

**Example usage:**

`locafix --report .` - Generate a report in the terminal, the localization files are in the current directory.

`localfix --files Users/example/Desktop --report Users/example/Documents` - Generate a report to the Documents folder, the localization files are on the desktop.

`localfix --correct` - The report is not generated, files in the current directory are corrected.

**Screenshots:**

<img width="697" alt="example_usage2" src="https://github.com/user-attachments/assets/89091db3-9394-4e88-9dc2-04b3f0d847b6">

<img width="828" alt="example_usage_1" src="https://github.com/user-attachments/assets/62b62f36-8622-43b2-b80a-482b395aea53">



