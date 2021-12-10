import Foundation

public struct Pattern {

    private let _pattern: _Pattern

    init(pattern: _Pattern) {
        _pattern = pattern
    }

    func color(at worldPoint: Tuple, objectTransform: Matrix) -> Color {
        return _pattern.color(at: worldPoint, objectTransform: objectTransform)
    }
}

protocol _Pattern {

    func color(at worldPoint: Tuple, objectTransform: Matrix) -> Color
}

#if TEST
import XCTest

final class PatternTests: XCTestCase {
}
#endif
