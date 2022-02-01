import Foundation

extension Pattern {

    public static func gradient(_ left: Color, _ right: Color, _ transform: Matrix = .identity) -> Pattern {
        let pattern = _GradientPattern(left, right, transform)
        return Pattern(pattern: pattern)
    }
}

private struct _GradientPattern: _Pattern {

    let left: Color
    let right: Color
    let transform: Matrix

    init(_ left: Color, _ right: Color, _ transform: Matrix) {
        self.left = left
        self.right = right
        self.transform = transform
    }

    func color(at localPoint: Point) -> Color {
        let distance = right - left
        let fraction = localPoint.x - localPoint.x.floor()

        return left + distance * fraction
    }
}

#if TEST
import XCTest

extension PatternTests {

    func test_gradient_color() {
        let pattern = Pattern.gradient(.white, .black, .identity)
        XCTAssertEqual(pattern.color(at: Point(0, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(0.25, 0, 0)), .rgb(0.75, 0.75, 0.75))
        XCTAssertEqual(pattern.color(at: Point(0.5, 0, 0)), .rgb(0.5, 0.5, 0.5))
        XCTAssertEqual(pattern.color(at: Point(0.75, 0, 0)), .rgb(0.25, 0.25, 0.25))
    }
}
#endif
