import Foundation

enum UnitTextNormalizer {
    static func normalize(_ raw: String) -> String {
        let trimmed = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: ".", with: "")

        guard !trimmed.isEmpty else { return "" }

        let tokens = trimmed.split(separator: " ").map { singularToken(String($0)) }
        return tokens.joined(separator: " ")
    }

    private static func singularToken(_ token: String) -> String {
        let irregular: [String: String] = [
            "filets": "filet",
            "fillets": "fillet",
            "teeth": "tooth",
            "loaves": "loaf",
            "knives": "knife",
            "leaves": "leaf",
        ]
        if let mapped = irregular[token] {
            return mapped
        }

        if token.hasSuffix("ies"), token.count > 3 {
            return String(token.dropLast(3)) + "y"
        }

        if token.hasSuffix("es"), token.count > 3,
            (token.hasSuffix("ches")
                || token.hasSuffix("shes")
                || token.hasSuffix("xes")
                || token.hasSuffix("zes")
                || token.hasSuffix("ses"))
        {
            return String(token.dropLast(2))
        }

        if token.hasSuffix("s"), token.count > 3,
            !token.hasSuffix("ss"),
            !token.hasSuffix("us"),
            !token.hasSuffix("is")
        {
            return String(token.dropLast())
        }

        return token
    }
}
