import Foundation

public enum Globals {

    /// - Note: Textures used within scenes are searched in this directory.
    public static var readDirectoryURL: URL?
}

enum Constants {

    static let maxRecursionDepth = 5
    static let defaultBackgroundColor = Color.black
}

public func printError(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator, to: &_standardError)
}

private struct _StderrOutputStream: TextOutputStream {

    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

private var _standardError = _StderrOutputStream()
