import Foundation

extension Pattern {

    public static func stripe(_ left: Color, _ right: Color, _ transform: Matrix = .identity) -> Pattern {
        let pattern = _StripePattern(left, right, transform: transform)
        return Pattern(pattern: pattern)
    }
}

private struct _StripePattern {

    let a: Color
    let b: Color
    let transform: Matrix

    public init(_ a: Color, _ b: Color, transform: Matrix = .identity) {
        self.a = a
        self.b = b
        self.transform = transform
    }

    fileprivate func _color(at localPoint: Tuple) -> Color {
        if localPoint.x.floor().truncatingRemainder(dividingBy: 2) == 0 {
            return a
        }

        return b
    }
}

extension _StripePattern: _Pattern {

    func color(at worldPoint: Tuple, objectTransform: Matrix = .identity) -> Color {
        let objectPoint = objectTransform.inversed() * worldPoint
        let patternPoint = transform.inversed() * objectPoint

        return _color(at: patternPoint)
    }
}

#if TEST
import XCTest

extension PatternTests {

    func test_color_constantInY() {
        let pattern = _StripePattern(.white, .black)
        XCTAssertEqual(pattern._color(at: .point(0, 0, 0)), .white)
        XCTAssertEqual(pattern._color(at: .point(0, 1, 0)), .white)
        XCTAssertEqual(pattern._color(at: .point(0, 2, 0)), .white)
    }

    func test_color_constantInZ() {
        let pattern = _StripePattern(.white, .black)
        XCTAssertEqual(pattern._color(at: .point(0, 0, 0)), .white)
        XCTAssertEqual(pattern._color(at: .point(0, 0, 1)), .white)
        XCTAssertEqual(pattern._color(at: .point(0, 0, 2)), .white)
    }

    func test_color_alternatesInX() {
        let pattern = _StripePattern(.white, .black)

        XCTAssertEqual(pattern._color(at: .point(0, 0, 0)), .white)
        XCTAssertEqual(pattern._color(at: .point(0.9, 0, 0)), .white)
        XCTAssertEqual(pattern._color(at: .point(1, 0, 0)), .black)
        XCTAssertEqual(pattern._color(at: .point(-0.1, 0, 0)), .black)
        XCTAssertEqual(pattern._color(at: .point(-1, 0, 0)), .black)
        XCTAssertEqual(pattern._color(at: .point(-1.1, 0, 0)), .white)
    }

    func test_objectTransformation() {
        let pattern = _StripePattern(.white, .black)
        XCTAssertEqual(pattern.color(at: .point(1.5, 0, 0), objectTransform: .scaling(2, 2, 2)), .white)
    }

    func test_patternTransformation() {
        let pattern = _StripePattern(.white, .black, transform: .scaling(2, 2, 2))
        XCTAssertEqual(pattern.color(at: .point(1.5, 0, 0)), .white)
    }

    func test_objectAndPatternTransformation() {
        let pattern = _StripePattern(.white, .black, transform: .translation(0.5, 0, 0))
        XCTAssertEqual(pattern.color(at: .point(2.5, 0, 0), objectTransform: .scaling(2, 2, 2)), .white)
    }
}
#endif
