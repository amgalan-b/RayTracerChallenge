import Foundation

extension Pattern {

    public static func test(transform: Matrix = .identity) -> Pattern {
        let pattern = _TestPattern(transform: transform)
        return Pattern(pattern: pattern)
    }
}

private struct _TestPattern: _Pattern {

    let transform: Matrix

    init(transform: Matrix) {
        self.transform = transform
    }

    func color(at localPoint: Point) -> Color {
        return Color(red: localPoint.x, green: localPoint.y, blue: localPoint.z)
    }
}

#if TEST
import XCTest

extension PatternTests {

    func test_testPattern() {
        let p1 = Pattern.test(transform: .scaling(2, 2, 2))
        let p2 = Pattern.test()

        XCTAssertEqual(p1.color(at: Point(2, 3, 4)), .rgb(1, 1.5, 2))
        XCTAssertEqual(p2.color(at: Point(3, 2, 1)), .rgb(3, 2, 1))
    }
}
#endif
