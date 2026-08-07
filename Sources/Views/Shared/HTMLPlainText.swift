import Foundation

enum HTMLPlainText {
    static func convert(_ html: String) -> String {
        var text = html

        let blockTags = ["</p>", "<br>", "<br/>", "<br />", "</div>", "</li>", "</tr>"]
        for tag in blockTags {
            text = text.replacingOccurrences(of: tag, with: "\n", options: .caseInsensitive)
        }

        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        let entities: [String: String] = [
            "&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
            "&quot;": "\"", "&#39;": "'", "&apos;": "'"
        ]
        for (entity, value) in entities {
            text = text.replacingOccurrences(of: entity, with: value)
        }

        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
