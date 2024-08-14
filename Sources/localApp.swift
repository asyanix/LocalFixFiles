//
//  File.swift
//  
//
//  Created by Асиет Чеуж on 09.08.2024.
//

import Foundation

struct localCommands
{
    let reportPath: String
    
    init(reportPath: String) {
        self.reportPath = reportPath
    }
}

func titleFormat(_ text: String) -> String {
    let color = "\u{001B}[93m"
    let style = "\u{001B}[1m"
    return "\(style)\(color)\(text)\u{001B}[0m"
}

func keysFormat(fileName: String, keys: Set<String>) -> String
{
    let color = "\u{001B}[31m"
    let style = "\u{001B}[1m"
    var keysText = String()
    
    keysText.append("\n\n-\(style)\(fileName)\u{001B}[0m")
    keys.forEach { key in
        keysText.append("\n  -\(color)`\(key)`\u{001B}[0m")
    }
    return keysText
}
