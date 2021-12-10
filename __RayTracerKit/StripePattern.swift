import Foundation

final class StripedPattern {

    let a: Color
    let b: Color

    init(_ a: Color, _ b: Color) {
        self.a = a
        self.b = b
    }

    func color(at point: Tuple) -> Color {
        if point.x.floor().truncatingRemainder(dividingBy: 2) == 0 {
            return a
        }

        return b
    }
}

#if TEST
import XCTest

final class PatternTest: XCTestCase {

    func test_color_constantInY() {
        let pattern = StripedPattern(.white, .black)
        XCTAssertEqual(pattern.color(at: .point(0, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: .point(0, 1, 0)), .white)
        XCTAssertEqual(pattern.color(at: .point(0, 2, 0)), .white)
    }

    func test_color_constantInZ() {
        let pattern = StripedPattern(.white, .black)
        XCTAssertEqual(pattern.color(at: .point(0, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: .point(0, 0, 1)), .white)
        XCTAssertEqual(pattern.color(at: .point(0, 0, 2)), .white)
    }

    func test_color_alternatesInX() {
        let pattern = StripedPattern(.white, .black)

        XCTAssertEqual(pattern.color(at: .point(0, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: .point(0.9, 0, 0)), .white)
        XCTAssertEqual(pattern.color(at: .point(1, 0, 0)), .black)
        XCTAssertEqual(pattern.color(at: .point(-0.1, 0, 0)), .black)
        XCTAssertEqual(pattern.color(at: .point(-1, 0, 0)), .black)
        XCTAssertEqual(pattern.color(at: .point(-1.1, 0, 0)), .white)
    }
}
#endif
