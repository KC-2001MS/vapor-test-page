import Markdown

/// MarkdownをHTMLに変換する
///
/// 元サイトの remark（remark-gfm・remark-breaks）＋ rehype-raw と同じ結果になるようにしている。
/// - 段落内の改行は `<br>` にする（remark-breaks）
/// - 表・打ち消し線・チェックボックス・脚注に対応する（remark-gfm）
/// - Markdown内のHTMLはそのまま出力する（rehype-raw）
/// - `/` から始まるリンクと画像には、サイトの公開パス（`basePath`）を付ける
struct MarkdownRenderer: Sendable {
    /// サイトの公開パス（例：`/swift-vapor-test-page`。ルートに置く場合は空）
    var basePath: String = ""
    /// 画像（`![]()`）に付けるクラス
    var imageClass: String? = nil

    func render(_ markdown: String) -> String {
        let footnotes = Footnotes(markdown)
        var html = renderBlocks(footnotes.source)
        if !footnotes.definitions.isEmpty {
            html += footnotes.section { renderBlocks($0) }
        }
        return html
    }

    private func renderBlocks(_ markdown: String) -> String {
        // スマートクォートは remark にない変換のため無効にする
        let document = Document(parsing: markdown, options: [.disableSmartOpts])
        var walker = HTMLWalker(basePath: basePath, imageClass: imageClass)
        walker.visit(document)
        return walker.result
    }
}

// MARK: - HTMLの出力

private struct HTMLWalker: MarkupWalker {
    let basePath: String
    let imageClass: String?
    var result = ""
    /// 項目の間に空行のないリスト（中の段落を `<p>` で囲まない）の中か
    private var inTightList = false

    init(basePath: String, imageClass: String?) {
        self.basePath = basePath
        self.imageClass = imageClass
    }

    // MARK: ブロック要素

    mutating func visitHeading(_ heading: Heading) {
        result += "<h\(heading.level)>"
        descendInto(heading)
        result += "</h\(heading.level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) {
        if inTightList {
            descendInto(paragraph)
            result += "\n"
        } else {
            result += "<p>"
            descendInto(paragraph)
            result += "</p>\n"
        }
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        let wasTight = inTightList
        inTightList = false
        result += "<blockquote>\n"
        descendInto(blockQuote)
        result += "</blockquote>\n"
        inTightList = wasTight
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let language = codeBlock.language?.split(separator: " ").first.map { " class=\"language-\(HTML.escape(String($0)))\"" } ?? ""
        result += "<pre><code\(language)>\(HTML.escape(codeBlock.code))</code></pre>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        result += "<hr>\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        result += html.rawHTML
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        visitList(unorderedList, open: "<ul>", close: "</ul>")
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        let start = orderedList.startIndex != 1 ? " start=\"\(orderedList.startIndex)\"" : ""
        visitList(orderedList, open: "<ol\(start)>", close: "</ol>")
    }

    private mutating func visitList(_ list: some ListItemContainer, open: String, close: String) {
        let wasTight = inTightList
        inTightList = Self.isTight(list)
        result += open + "\n"
        descendInto(list)
        result += close + "\n"
        inTightList = wasTight
    }

    mutating func visitListItem(_ listItem: ListItem) {
        result += "<li>"
        if let checkbox = listItem.checkbox {
            result += checkbox == .checked ? "<input type=\"checkbox\" checked disabled> " : "<input type=\"checkbox\" disabled> "
        }
        descendInto(listItem)
        result += "</li>\n"
    }

    mutating func visitTable(_ table: Table) {
        result += "<table>\n<thead>\n<tr>\n"
        for (index, cell) in table.head.cells.enumerated() {
            visitTableCell(cell, element: "th", alignment: table.columnAlignments[safe: index] ?? nil)
        }
        result += "</tr>\n</thead>\n"
        if !table.body.isEmpty {
            result += "<tbody>\n"
            for row in table.body.rows {
                result += "<tr>\n"
                for (index, cell) in row.cells.enumerated() {
                    visitTableCell(cell, element: "td", alignment: table.columnAlignments[safe: index] ?? nil)
                }
                result += "</tr>\n"
            }
            result += "</tbody>\n"
        }
        result += "</table>\n"
    }

    private mutating func visitTableCell(_ cell: Table.Cell, element: String, alignment: Table.ColumnAlignment?) {
        result += "<\(element)"
        if let alignment {
            result += " align=\"\(alignment)\""
        }
        result += ">"
        descendInto(cell)
        result += "</\(element)>\n"
    }

    // MARK: インライン要素

    mutating func visitText(_ text: Text) {
        result += HTML.escape(text.string)
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        result += "<code>\(HTML.escape(inlineCode.code))</code>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        result += "<em>"
        descendInto(emphasis)
        result += "</em>"
    }

    mutating func visitStrong(_ strong: Strong) {
        result += "<strong>"
        descendInto(strong)
        result += "</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        result += "<del>"
        descendInto(strikethrough)
        result += "</del>"
    }

    mutating func visitLink(_ link: Link) {
        result += "<a"
        if let destination = link.destination {
            result += " href=\"\(HTML.escape(resolve(destination)))\""
        }
        if let title = link.title, !title.isEmpty {
            result += " title=\"\(HTML.escape(title))\""
        }
        result += ">"
        descendInto(link)
        result += "</a>"
    }

    mutating func visitImage(_ image: Image) {
        result += "<img"
        if let source = image.source {
            result += " src=\"\(HTML.escape(resolve(source)))\""
        }
        result += " alt=\"\(HTML.escape(image.plainText))\""
        if let title = image.title, !title.isEmpty {
            result += " title=\"\(HTML.escape(title))\""
        }
        if let imageClass {
            result += " class=\"\(HTML.escape(imageClass))\""
        }
        result += ">"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) {
        result += inlineHTML.rawHTML
    }

    // remark-breaks と同じく、段落内の改行も `<br>` にする
    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        result += "<br>\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        result += "<br>\n"
    }

    // MARK: 補助

    /// サイト内の絶対パスに公開パスを付ける
    private func resolve(_ url: String) -> String {
        guard url.hasPrefix("/"), !url.hasPrefix("//") else { return url }
        return basePath + url
    }

    /// CommonMarkの規則で、項目の間や項目内のブロックの間に空行がなければ「詰めたリスト」
    private static func isTight(_ list: some ListItemContainer) -> Bool {
        let items = Array(list.listItems)
        // 項目の範囲は後ろの空行まで含むため、項目内の最後のブロックの終わりと比べる
        for (item, next) in zip(items, items.dropFirst()) {
            let last = item.childCount > 0 ? item.child(at: item.childCount - 1) : nil
            if let end = (last ?? item).range?.upperBound.line, let start = next.range?.lowerBound.line, start - end > 1 {
                return false
            }
        }
        for item in items {
            let blocks = Array(item.children)
            for (block, next) in zip(blocks, blocks.dropFirst()) {
                if let end = block.range?.upperBound.line, let start = next.range?.lowerBound.line, start - end > 1 {
                    return false
                }
            }
        }
        return true
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
