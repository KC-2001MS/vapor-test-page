import Foundation

/// GFMの脚注（`[^1]` と `[^1]: 本文`）
///
/// swift-markdown は脚注に対応していないため、Markdownを解析する前に
/// 参照をHTMLに置き換え、定義を取り出しておく。出力するHTMLは remark-gfm と同じ形にしている。
struct Footnotes {
    struct Definition {
        var label: String
        var text: String
        /// 本文中で参照された回数
        var referenceCount: Int
    }

    /// 参照を置き換え、定義を取り除いたMarkdown
    private(set) var source = ""
    /// 参照された順の定義
    private(set) var definitions: [Definition] = []

    init(_ markdown: String) {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        // 定義を取り出す（コードブロックの中は対象外）
        var texts: [String: String] = [:]
        var bodyLines: [(line: String, isCode: Bool)] = []
        var fence: String?
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let current = fence {
                if trimmed.hasPrefix(current) { fence = nil }
                bodyLines.append((line, true))
                continue
            }
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                fence = String(trimmed.prefix(3))
                bodyLines.append((line, true))
                continue
            }
            if let (label, text) = Self.parseDefinition(line) {
                texts[label] = text
                continue
            }
            bodyLines.append((line, false))
        }

        // 参照を置き換える（番号は最初に参照された順）
        var order: [String] = []
        var counts: [String: Int] = [:]
        source = bodyLines.map { line, isCode in
            guard !isCode, !texts.isEmpty else { return line }
            return Self.replaceReferences(in: line) { label in
                guard texts[label] != nil else { return nil }
                if counts[label] == nil { order.append(label) }
                counts[label, default: 0] += 1
                let number = order.firstIndex(of: label)! + 1
                let count = counts[label]!
                let id = Self.id(label) + (count > 1 ? "-\(count)" : "")
                return "<sup><a href=\"#user-content-fn-\(Self.id(label))\" id=\"user-content-fnref-\(id)\" data-footnote-ref=\"\" aria-describedby=\"footnote-label\">\(number)</a></sup>"
            }
        }.joined(separator: "\n")

        definitions = order.map { Definition(label: $0, text: texts[$0]!, referenceCount: counts[$0]!) }
    }

    /// 末尾に置く脚注の一覧（`render` で定義の本文をHTMLにする）
    func section(render: (String) -> String) -> String {
        var html = "<section data-footnotes=\"\" class=\"footnotes\"><h2 class=\"sr-only\" id=\"footnote-label\">Footnotes</h2>\n<ol>\n"
        for (index, definition) in definitions.enumerated() {
            let id = Self.id(definition.label)
            var backReferences: [String] = []
            for count in 1...definition.referenceCount {
                let suffix = count > 1 ? "-\(count)" : ""
                let label = count > 1 ? "↩<sup>\(count)</sup>" : "↩"
                backReferences.append("<a href=\"#user-content-fnref-\(id)\(suffix)\" data-footnote-backref=\"\" aria-label=\"Back to reference \(index + 1)\(suffix)\" class=\"data-footnote-backref\">\(label)</a>")
            }
            var body = render(definition.text).trimmingCharacters(in: .whitespacesAndNewlines)
            let links = " " + backReferences.joined(separator: " ")
            if body.hasSuffix("</p>") {
                body.insert(contentsOf: links, at: body.index(body.endIndex, offsetBy: -4))
            } else {
                body += links
            }
            html += "<li id=\"user-content-fn-\(id)\">\n\(body)\n</li>\n"
        }
        html += "</ol>\n</section>\n"
        return html
    }

    // MARK: - 解析

    /// `[^label]: text` の行
    private static func parseDefinition(_ line: String) -> (String, String)? {
        guard line.hasPrefix("[^"), let close = line.range(of: "]:") else { return nil }
        let label = String(line[line.index(line.startIndex, offsetBy: 2)..<close.lowerBound])
        guard !label.isEmpty, !label.contains("]") else { return nil }
        let text = line[close.upperBound...].trimmingCharacters(in: .whitespaces)
        return (label, text)
    }

    /// 行内の `[^label]` を置き換える（`replacement` が `nil` を返したらそのまま残す）
    private static func replaceReferences(in line: String, replacement: (String) -> String?) -> String {
        var result = ""
        var rest = line[...]
        while let open = rest.range(of: "[^") {
            result += rest[..<open.lowerBound]
            let afterOpen = rest[open.upperBound...]
            if let close = afterOpen.firstIndex(of: "]"),
               case let label = String(afterOpen[..<close]),
               !label.isEmpty,
               let html = replacement(label) {
                result += html
                rest = afterOpen[afterOpen.index(after: close)...]
            } else {
                result += "[^"
                rest = afterOpen
            }
        }
        return result + rest
    }

    /// HTMLのidに使う形（remark-gfmと同じく小文字にする）
    private static func id(_ label: String) -> String {
        HTML.escape(label.lowercased())
    }
}
