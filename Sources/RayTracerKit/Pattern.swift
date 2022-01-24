import Foundation

public struct Pattern {

    private let _pattern: _Pattern

    init(pattern: _Pattern) {
        _pattern = pattern
    }

    func color(at worldPoint: Tuple, objectTransform: Matrix = .identity) -> Color {
        let objectPoint = objectTransform.inversed() * worldPoint
        let patternPoint = _pattern.transform.inversed() * objectPoint

        return _pattern.color(at: patternPoint)
    }
}

protocol _Pattern {

    var transform: Matrix { get }

    func color(at localPoint: Tuple) -> Color
}

#if TEST
import XCTest

final class PatternTests: XCTestCase {

    func test_objectTransformation() {
        let pattern = Pattern.stripe(.white, .black)
        XCTAssertEqual(pattern.color(at: .point(1.5, 0, 0), objectTransform: .scaling(2, 2, 2)), .white)
    }

    func test_patternTransformation() {
        let pattern = Pattern.stripe(.white, .black, .scaling(2, 2, 2))
        XCTAssertEqual(pattern.color(at: .point(1.5, 0, 0)), .white)
    }

    func test_objectAndPatternTransformation() {
        let pattern = Pattern.stripe(.white, .black, .translation(0.5, 0, 0))
        XCTAssertEqual(pattern.color(at: .point(2.5, 0, 0), objectTransform: .scaling(2, 2, 2)), .white)
    }
}
#endif
