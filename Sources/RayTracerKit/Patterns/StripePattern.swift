import Foundation

extension Pattern {

    static func stripe(_ left: Color, _ right: Color, _ transform: Matrix = .identity) -> Pattern {
        return .stripe(StripePattern(left, right, transform: transform))
    }
}

struct StripePattern: PatternProtocol, Equatable {

    let left: Color
    let right: Color
    let transform: Matrix

    init(_ left: Color, _ right: Color, transform: Matrix) {
        self.left = left
        self.right = right
        self.transform = transform
    }

    func color(at localPoint: Point) -> Color {
        if localPoint.x.floor().truncatingRemainder(dividingBy: 2) == 0 {
            return left
        }

        return right
    }
}

#if TEST
import XCTest

extension PatternTests {

    func test_color_constantInY() {
        let pattern = Pattern.stripe(.white, .black)

        XCTAssertEqual(pattern.color(at: Point(0, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(0, 1, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(0, 2, 0)), .white)
    }

    func test_color_constantInZ() {
        let pattern = Pattern.stripe(.white, .black)

        XCTAssertEqual(pattern.color(at: Point(0, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(0, 0, 1)), .white)
        XCTAssertEqual(pattern.color(at: Point(0, 0, 2)), .white)
    }

    func test_color_alternatesInX() {
        let pattern = Pattern.stripe(.white, .black)

        XCTAssertEqual(pattern.color(at: Point(0, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(0.9, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(1, 0, 0)), .black)
        XCTAssertEqual(pattern.color(at: Point(-0.1, 0, 0)), .black)
        XCTAssertEqual(pattern.color(at: Point(-1, 0, 0)), .black)
        XCTAssertEqual(pattern.color(at: Point(-1.1, 0, 0)), .white)
    }
}
#endif
