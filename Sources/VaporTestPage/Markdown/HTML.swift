import Foundation

/// HTMLの文字列を扱う補助
enum HTML {
    /// テキストや属性値として埋め込めるようにエスケープする
    static func escape(_ string: String) -> String {
        var result = ""
        result.reserveCapacity(string.utf8.count)
        for character in string {
            switch character {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            default: result.append(character)
            }
        }
        return result
    }

    /// URLのパスとして使えない文字（空白など）をパーセントエンコードする
    static func encodePath(_ path: String) -> String {
        path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
    }
}
