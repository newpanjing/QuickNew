import Foundation

enum MenuItemKind: String, CaseIterable, Identifiable, Codable {
    case folder
    case emptyFile
    case markdown
    case text
    case richText
    case word
    case excel
    case powerpoint
    case csv
    case json
    case yaml
    case html
    case css
    case javascript
    case swift
    case shell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .folder: L10n.string("menu.item.folder")
        case .emptyFile: L10n.string("menu.item.empty_file")
        case .markdown: L10n.string("menu.item.markdown")
        case .text: L10n.string("menu.item.text")
        case .richText: L10n.string("menu.item.rtf")
        case .word: L10n.string("menu.item.word")
        case .excel: L10n.string("menu.item.excel")
        case .powerpoint: L10n.string("menu.item.powerpoint")
        case .csv: L10n.string("menu.item.csv")
        case .json: L10n.string("menu.item.json")
        case .yaml: L10n.string("menu.item.yaml")
        case .html: L10n.string("menu.item.html")
        case .css: L10n.string("menu.item.css")
        case .javascript: L10n.string("menu.item.javascript")
        case .swift: L10n.string("menu.item.swift")
        case .shell: L10n.string("menu.item.shell")
        }
    }

    var iconResourceName: String {
        switch self {
        case .folder: "icon-folder"
        case .emptyFile: "icon-file"
        case .markdown: "icon-md"
        case .text: "icon-txt"
        case .richText: "icon-rtf"
        case .word: "icon-docx"
        case .excel: "icon-xlsx"
        case .powerpoint: "icon-pptx"
        case .csv: "icon-csv"
        case .json: "icon-json"
        case .yaml: "icon-yaml"
        case .html: "icon-html"
        case .css: "icon-css"
        case .javascript: "icon-js"
        case .swift: "icon-swift"
        case .shell: "icon-sh"
        }
    }

    var defaultName: String {
        switch self {
        case .folder: L10n.string("file.default.folder")
        case .emptyFile: L10n.string("file.default.empty_file")
        case .markdown: "\(L10n.string("file.default.untitled")).md"
        case .text: "\(L10n.string("file.default.untitled")).txt"
        case .richText: "\(L10n.string("file.default.untitled")).rtf"
        case .word: "\(L10n.string("file.default.untitled")).docx"
        case .excel: "\(L10n.string("file.default.untitled")).xlsx"
        case .powerpoint: "\(L10n.string("file.default.untitled")).pptx"
        case .csv: "\(L10n.string("file.default.untitled")).csv"
        case .json: "\(L10n.string("file.default.untitled")).json"
        case .yaml: "\(L10n.string("file.default.untitled")).yaml"
        case .html: "\(L10n.string("file.default.untitled")).html"
        case .css: "\(L10n.string("file.default.untitled")).css"
        case .javascript: "\(L10n.string("file.default.untitled")).js"
        case .swift: "\(L10n.string("file.default.untitled")).swift"
        case .shell: "\(L10n.string("file.default.untitled")).sh"
        }
    }

    var defaultContents: Data? {
        switch self {
        case .folder: nil
        case .emptyFile: Data()
        case .markdown: "# \(L10n.string("file.default.untitled"))\n".data(using: .utf8)
        case .text: Data()
        case .richText:
            "{\\rtf1\\ansi\\deff0{\\fonttbl{\\f0 -apple-system;}}\\f0\\fs24 }\n"
                .data(using: .utf8)
        case .word:
            nil
        case .excel:
            nil
        case .powerpoint:
            nil
        case .csv:
            "\(L10n.string("file.default.csv.name")),\(L10n.string("file.default.csv.value"))\n".data(using: .utf8)
        case .json:
            "{\n  \n}\n".data(using: .utf8)
        case .yaml:
            "---\n".data(using: .utf8)
        case .html:
            """
            <!doctype html>
            <html lang="\(L10n.string("file.default.html.lang"))">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <title>\(L10n.string("file.default.untitled"))</title>
            </head>
            <body>
            </body>
            </html>
            """.data(using: .utf8)
        case .css:
            "body {\n  margin: 0;\n}\n".data(using: .utf8)
        case .javascript:
            "console.log(\"Hello, QuickNew\");\n".data(using: .utf8)
        case .swift:
            "import Foundation\n\n".data(using: .utf8)
        case .shell:
            "#!/bin/zsh\n\n".data(using: .utf8)
        }
    }

    var isDirectory: Bool {
        self == .folder
    }

    var templateResourceName: String? {
        switch self {
        case .word: "template-docx"
        case .excel: "template-xlsx"
        case .powerpoint: "template-pptx"
        default: nil
        }
    }

    var templateResourceExtension: String? {
        switch self {
        case .word: "docx"
        case .excel: "xlsx"
        case .powerpoint: "pptx"
        default: nil
        }
    }
}
