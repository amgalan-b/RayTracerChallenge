import Foundation

extension Pattern {

    public static func checker(_ left: Color, _ right: Color, _ transform: Matrix = .identity) -> Pattern {
        return .checker(CheckerPattern(left, right, transform))
    }
}

struct CheckerPattern: PatternProtocol, Equatable {

    let left: Color
    let right: Color
    let transform: Matrix

    init(_ left: Color, _ right: Color, _ transform: Matrix) {
        self.left = left
        self.right = right
        self.transform = transform
    }

    func color(at localPoint: Point) -> Color {
        let sum = localPoint.x.floor() + localPoint.y.floor() + localPoint.z.floor()
        if sum.truncatingRemainder(dividingBy: 2).isAlmostEqual(to: 0, tolerance: .tolerance) {
            return left
        }

        return right
    }
}

#if TEST
import XCTest

extension PatternTests {

    func test_checker_color() {
        let pattern = Pattern.checker(.white, .black)

        XCTAssertEqual(pattern.color(at: Point(0, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(0.99, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(1.01, 0, 0)), .black)

        XCTAssertEqual(pattern.color(at: Point(0, 0.99, 0)), .white)
        XCTAssertEqual(pattern.color(at: Point(0, 1.01, 0)), .black)

        XCTAssertEqual(pattern.color(at: Point(0, 0, 0.99)), .white)
        XCTAssertEqual(pattern.color(at: Point(0, 0, 1.01)), .black)
    }
}
#endif
